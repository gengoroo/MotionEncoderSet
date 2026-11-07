function Model = cortical_som_train(MOV_input,pn_save,varargin)

% 2026_11_05　Layerを詳細情報残すように変更

mapSize = 6;%default
tagFig = '';
miniBatchSize = 16;%2026_11_05 minibatch処理
for ii = 1:nargin-2
    if strcmp('mapSize',varargin{ii})
        mapSize = varargin{ii+1};
    end
    if strcmp('tagFig',varargin{ii})
        tagFig = varargin{ii+1};
    end
    if strcmp('miniBatchSize',varargin{ii})
        miniBatchSize = varargin{ii+1};
    end
end

yn_report = 'y';

%% =====================================================
% Encoder-only cortical representation learner
% MATLAB R2024a
% RTX3060 6GB compatible
%% =====================================================

rng(1)

%% PARAMETERS

%latentDim = mapSize^2;%64; 2026_11_01 mapSize adjustable
latentDim = 256;% nodeの数と同じでは少なすぎる,多すぎるとサンプル距離感が似てきてBMUが不安定になりHitCountが偏る

numEpoch = 50;

rho = 0.10;

betaKL = 0;%0.01;

gammaW = 1e-4;

lambdaVar = 0.1;

lrEncoder = 1e-6;%1e-3;
lrAlpha   = 2e-4;
lrW       = 1e-6;

Winh = ones(latentDim,'single');

Winh(1:latentDim+1:end)=0;%Winh(1:65:end)=0;2026_11_01 mapSize adjustable

Winh = Winh ./ sum(Winh,2);

%% =====================================================
% Resize
%% =====================================================


nMovData = size(MOV_input,4);
nFrames = size(MOV_input,3);
nSide = size(MOV_input,1);% 2026_11_05 nSide_CNN variable
nSide_max = 128;% 2026_11_05 nSide_CNN variable

% 2026_11_05 nSide_CNN variable
if nSide > nSide_max
    nSide_CNN = nSide_max;
    fprintf('Resizing movies for 3DCNN to [%d, %d, nFrames]\n',nSide_CNN,nSide_CNN)
    for k = 1:nMovData
        MOV_adjust{k} = single(imresize3(MOV_input(:,:,:,k),[nSide_max nSide_max nFrames]));
    end
else
    nSide_CNN = nSide;
    for k = 1:nMovData
        MOV_adjust{k} = single(MOV_input(:,:,:,k));
    end
end

%% =====================================================
% Encoder
%% =====================================================

layers = [

%image3dInputLayer([128 128 nFrames 1],Normalization="none")
image3dInputLayer([nSide_CNN nSide_CNN nFrames 1],Normalization="none")% 2026_11_05 nSide_CNN variable

convolution3dLayer(3,16, Padding="same")
batchNormalizationLayer
reluLayer

%maxPooling3dLayer(2,Stride=2)%2026_11_05情報量増やすため削除
maxPooling3dLayer([2 2 1],Stride=[2 2 1])%2026_11_05情報量増やすため交換

convolution3dLayer(3,32, Padding="same")
batchNormalizationLayer
reluLayer

%maxPooling3dLayer(2,Stride=2)%2026_11_05情報量増やすため削除

convolution3dLayer(3,64, Padding="same")
batchNormalizationLayer
reluLayer

convolution3dLayer(1,8,Padding="same")
%globalAveragePooling3dLayer %2026_11_05情報量増やすため削除
flattenLayer
fullyConnectedLayer(512)

dropoutLayer(0.2)

fullyConnectedLayer(128)

reluLayer

fullyConnectedLayer(latentDim)

%reluLayer
%tanhLayer %2026_11_05情報量増やすため削除 SOMでは不要

];

EncoderNet = dlnetwork(layerGraph(layers));%2026_11_05 GPUに載せる
EncoderNet = dlupdate(@gpuArray,EncoderNet);%2026_11_05 GPUに載せる
%% =====================================================
% Learnable inhibition
%% =====================================================

alphaRaw = 0.25;%　固定dlarray(zeros(latentDim,1,'single'));
alphaRaw = gpuArray(alphaRaw);%2026_11_02 GPUに載せる

Winh = single(ones(latentDim));
Winh(1:65:end)=0;
Winh = Winh ./ sum(Winh,2);
Winh     = gpuArray(Winh);%2026_11_02 GPUに載せる

mask = ones(latentDim,'single');
mask(1:latentDim+1:end)=0;%mask(1:65:end)=0; 2026_11_01 mapSize adjustable
mask = dlarray(mask);
mask     = gpuArray(mask);%2026_11_02 GPUに載せる

%% =====================================================
% Adam states
%% =====================================================

avgE = [];
avgSqE = [];

%avgA = [];
%avgSqA = [];

avgW = [];
avgSqW = [];

iteration = 0;

%% =====================================================
% History
%% =====================================================

History.loss      = zeros(numEpoch,1);
History.KL        = zeros(numEpoch,1);
History.Wloss     = zeros(numEpoch,1);
History.VarLoss   = zeros(numEpoch,1);

History.active    = zeros(numEpoch,1);

History.alphaMean = zeros(numEpoch,1);
History.Wmean     = zeros(numEpoch,1);

%% =====================================================
% Training
%% =====================================================
fprintf('Total numEpoch=%d',numEpoch);

for epoch = 1:numEpoch

    betaKL_now = betaKL * min(epoch/20,1);
    epochLoss = [];

    %for iMovie = 1:numel(MOV_adjust)%2026_11_05 minibatch処理
    for iMovie = 1:miniBatchSize:numel(MOV_adjust)%2026_11_05 minibatch処理
        iteration = iteration + 1;

        %2026_11_05 minibatch処理
        idxEnd = min(iMovie+miniBatchSize-1,numel(MOV_adjust));%2026_11_05 minibatch処理
        nBatch = idxEnd-iMovie+1;%2026_11_05 minibatch処理
        Xbatch = zeros(nSide_CNN,nSide_CNN,nFrames,1,nBatch,'single');
        for k = 1:nBatch
            Xbatch(:,:,:,1,k) = single(MOV_adjust{iMovie+k-1});%動画を詰める
        end
        Xbatch = dlarray(gpuArray(Xbatch),"SSSCB");%GPUへ転送 (spatial spatial channel batch)
        %2026_11_05 minibatch処理

        %X = MOV_adjust{iMovie};
        %%X = reshape(X,128,128,nFrames,1);
        %X = reshape(X,nSide_CNN,nSide_CNN,nFrames,1);% 2026_11_05 nSide_CNN variable
        %%X = dlarray(X,"SSSC");%2026_11_05 GPUに載せる
        %X = gpuArray(single(X));%2026_11_05 GPUに載せる
        %X = dlarray(X,"SSSC");%2026_11_05 GPUに載せる
        X = Xbatch;

        %[loss, KLloss, Wloss, varLoss, activeFraction, gradE, gradA] = ...
        [loss, KLloss, Wloss, varLoss, activeFraction, latentVar, gradE] = ...
         dlfeval(@modelGradients, EncoderNet, X, alphaRaw, Winh, mask, rho, betaKL_now, gammaW,lambdaVar);

        gradE = clipGrad(gradE,0.01);%clipGrad(gradE,5);

                % デバッグ
        for k = 1:size(gradE,1)
            g = gradE.Value{k};
            if any(isnan(extractdata(g(:))))
                error('NaN detected in gradE')
            end
            if any(isinf(extractdata(g(:))))
                error('Inf detected in gradE')
            end
        end


        %gradA = clipGrad(gradA,0.5);
        [EncoderNet, avgE, avgSqE] = ...
         adamupdate(EncoderNet, gradE, avgE, avgSqE, iteration, lrEncoder);

                %デバッグ
        for k = 1:size(EncoderNet.Learnables,1)
            V = EncoderNet.Learnables.Value{k};
            if any(isnan(extractdata(V(:))))
                error('NaN detected in Encoder weights')
            end
        end

        if 1==2
        [alphaRaw, avgA, avgSqA] = ...
         adamupdate(alphaRaw, gradA, avgA, avgSqA, iteration, lrAlpha);
        end

        alphaRaw = max(min(alphaRaw,10),-10);%dlarray(max(min(extractdata(alphaRaw),10),-10));

        epochLoss(end+1) = ...
            gather(extractdata(loss));

    end

    alpha = 0.5*sigmoid(alphaRaw);
    History.loss(epoch) =  mean(epochLoss);
    History.KL(epoch) =  gather(extractdata(KLloss));
    History.Wloss(epoch) = double(Wloss);
    History.VarLoss(epoch)= latentVar;%gather(extractdata(varLoss));
    History.active(epoch)= double(activeFraction);
    History.alphaMean(epoch)= mean(alpha(:));%gather(extractdata(mean(alpha)));
    History.Wmean(epoch)= mean(Winh(:));

    if yn_report == 'y'
        fprintf('Epoch %03d | Loss %.4f | KL %.4f | Var %.4f | Active %.3f\n',...
             epoch, History.loss(epoch), History.KL(epoch), History.VarLoss(epoch), History.active(epoch));
    
        %Epochレポート
        fprintf('alpha %.4f  W %.4f\n',...
        mean(alpha(:)),...%gather(extractdata(mean(alpha))),...
        mean(Winh(:)));
    end

    History.loss(epoch) = gather(extractdata(loss));
    History.KL(epoch) = gather(extractdata(KLloss));
    History.Wloss(epoch) = double(Wloss);
    History.VarLoss(epoch) = gather(extractdata(varLoss));
    History.active(epoch) = double(activeFraction);
    History.alphaMean(epoch) = mean(alpha(:));% gather(extractdata(mean(alpha)));
    History.Wmean(epoch) = mean(Winh(:));

    %fprintf('mean(stdZ)=%.4f\n', ...
    %gather(extractdata(mean(stdZ))));
end

%% =====================================================
% Embedding
%% =====================================================

Embedding = zeros( ...
    numel(MOV_adjust), ...
    latentDim);

%Embedding診断
fprintf('\n');
fprintf('========================\n');
fprintf('Embedding Diagnostics\n');
fprintf('========================\n');

fprintf('Mean = %.6f\n', ...
    mean(Embedding(:)));

fprintf('Std = %.6f\n', ...
    std(Embedding(:)));

fprintf('Feature Std = %.6f\n', ...
    mean(std(Embedding,0,1)));


for iMovie = 1:numel(MOV_adjust)

    X = MOV_adjust{iMovie};

    %X = reshape(X,128,128,nFrames,1);% 2026_11_05 nSide_CNN variable
    X = reshape(X,nSide_CNN,nSide_CNN,nFrames,1);

    X = dlarray(X,"SSSC");

    Z = forward(EncoderNet,X);
    
    if any(isnan(extractdata(Z(:))))
        error('NaN detected immediately after Encoder')
    end
    
    %-----------------------------


    alpha = 0.5*sigmoid(alphaRaw);

    rowSum = sum(Winh,2) + 1e-6;

    Winh = Winh ./ rowSum;
    
    Zu = stripdims(Z);

    %alpha = stripdims(alpha);
    % alpha は普通の数値なので stripdims 不要
    
    % Winh は numeric のまま使う
    
    %inh = Zu;%Winh * Zu;%側方抑制を完全に切る
    
    Zinh = Zu;%Zu - 1e-4 .* alpha .* inh;
    
    %Zinh = max(Zinh,0);
    
    Embedding(iMovie,:) = ...
        gather(extractdata(Zinh(:)))';


end
%Embedding診断

fprintf('\n');

fprintf('Embedding Mean %.6f\n',...
    mean(Embedding(:)));

fprintf('Embedding Std %.6f\n',...
    std(Embedding(:)));

fprintf('Feature Std %.6f\n',...
    mean(std(Embedding,0,1)));


%Correlation表示
figure('Name',[tagFig '_EmbedCorr']);

imagesc(corr(Embedding'))

axis image

colorbar

title('Embedding Correlation')

%Collapse判定

embedDiversity = ...
    mean(std(Embedding,0,1));

fprintf( ...
    '\nEmbedding Diversity = %.6f\n',...
    embedDiversity);

if embedDiversity < 1e-3

    warning('Embedding Collapse Detected')

elseif embedDiversity < 1e-2

    warning('Weak Embedding Diversity')

else

    fprintf('Embedding Diversity OK\n')

end
%% =====================================================
% SOM
%% =====================================================

fprintf('Training SOM...\n')

netSOM = selforgmap([mapSize mapSize]);%selforgmap([8 8]);

netSOM = train( ...
    netSOM,...
    Embedding');

Y = netSOM(Embedding');

winner = vec2ind(Y);

%% =====================================================
% Save
%% =====================================================

Model.Embedding = Embedding;

Model.Winner = winner;

Model.alpha = alpha;%gather(extractdata(alpha));

Model.Winh = ...
    Winh;

Model.SOM = netSOM;

Model.History = History;

save([pn_save '\CorticalEncoder.mat'],'Model','-v7.3');

%% =====================================================
% Plot
%% =====================================================

figure('Name',[tagFig, '_History']);

subplot(2,2,1)
plot(History.loss)
title('Loss')

subplot(2,2,2)
plot(History.active)
title('Active Fraction')

subplot(2,2,3)
if numel(Model.alpha)==64
    imagesc(reshape(Model.alpha,8,8))
else
    imagesc(Model.alpha)
end
axis image
colorbar
title('Alpha Map')

subplot(2,2,4)
imagesc(Model.Winh)
colorbar
title('Winh')

%成功判定
fprintf('mean(std(Model.Embedding,0,1)) is %d should be >0.01(ideal 0.05)\n',mean(std(Model.Embedding,0,1)))
figure('Name',[tagFig, '_corrModel_Embedding']);
imagesc(corr(Model.Embedding'))
end

%% =====================================================
function [loss,...
          KLloss,...
          Wloss,...
          varLoss,...
          activeFraction,...
          latentVar,...
          gradE] ...
    = modelGradients( ...
        EncoderNet,...
        X,...
        alphaRaw,...
        Winh,...
        mask,...
        rho,...
        betaKL,...
        gammaW,...
        lambdaVar)

%% =====================================================
% Encoder
%% =====================================================
yn_report = 'n';
Z = forward(EncoderNet,X);

%fprintf('Z mean=%g max=%g min=%g\n', gather(extractdata(mean(Z(:)))), gather(extractdata(max(Z(:)))),gather(extractdata(min(Z(:)))));

if any(isnan(extractdata(X(:))))
    error('NaN detected in X')
end

if any(isnan(extractdata(Z(:))))
    error('NaN detected in Z')
end

Zu = stripdims(Z);

if any(isnan(Zu(:)))
    error('NaN detected in Zu')
end

% Z : [64 x 1]

%% =====================================================
% Learnable inhibition
%% =====================================================

alpha = 0.5 .* sigmoid(alphaRaw);

rowSum = sum(Winh,2);

rowSum(rowSum < 1e-6) = 1;

Winh = Winh ./ rowSum;

rowSum = sum(Winh,2);

rowSum(rowSum < 1e-6) = 1;

Winh = Winh ./ rowSum;

%% =====================================================
% Lateral inhibition
%% =====================================================

Zu = stripdims(Z);

%alpha = stripdims(alpha);

% Winh は numeric のまま使う

inh = Winh * Zu;

Zinh = Zu;%置換実験　Winhがcollapseの原因か？　Zu - 1e-4 .* alpha .* inh;

Zinh = max(Zinh,0);

if any(isnan(extractdata(Zu(:))))
    error('NaN detected in Zu')
end

if any(isnan(extractdata(inh(:))))
    error('NaN detected in inh')
end

if any(isnan(extractdata(Zinh(:))))
    error('NaN detected in Zinh')
end

%% =====================================================
% KL sparsity
%% =====================================================

rhoHat = mean(Zinh,2);

rhoHat = gather(extractdata(rhoHat));

rhoHat = min(max(rhoHat,1e-4),0.999);

rhoHat = dlarray(single(rhoHat));

KLloss = dlarray(single(0));%sum(rho .* log(rho./rhoHat) + (1-rho).*log((1-rho)./(1-rhoHat)),"all");

%% =====================================================
% Inhibitory weight penalty
%% =====================================================

Wloss = mean(abs(Winh),"all");

%% =====================================================
% Variance preservation
%% =====================================================

stdZ = std(Zinh,0,2);

varLoss = dlarray(single(0));%mean(max(0,0.5-stdZ));

%% =====================================================
% Activity monitor
%% =====================================================

activeFraction = ...
     mean(abs(Zinh(:)) > 1e-6);

%% =====================================================
% Total loss
%% =====================================================
%NaN検出

if any(isnan(extractdata(Zinh(:))))
    error('NaN detected in Zinh')
end

if any(isnan(alpha(:)))%any(isnan(extractdata(alpha(:))))
    error('NaN detected in alpha')
end

KLloss  = min(KLloss ,100);
Wloss   = min(Wloss  ,100);
varLoss = min(varLoss,100);



meanZ = mean(Zinh(:));
varZ = mean((Zinh(:)-meanZ).^2);
latentVar = double(extractdata(varZ));
loss = -varZ + 0.01*mean(Zinh.^2,"all");%mean(Zinh.^2,'all');%varLoss;%mean(Zinh.^2,"all");%gammaW * Wloss;%betaKL * KLloss + gammaW * Wloss - lambdaVar * varLoss;

if yn_report == 'y'
    fprintf('latentVar=%g ',latentVar);
end

%% =====================================================
% Gradients
%% =====================================================

%[gradE, gradA] = dlgradient(loss, EncoderNet.Learnables, alphaRaw);
%disp(class(loss)); 
if yn_report == 'y'
    fprintf('KLloss=%g Wloss=%g varLoss=%g Loss=%g \n', ...
        double(KLloss), ...
        double(Wloss), ...
        double(varLoss), ...
        double(loss));
end
if isnan(double(loss))
    error('Loss became NaN');
end
if isinf(double(loss))
    error('loss became inf')
end
gradE = dlgradient(loss,EncoderNet.Learnables);%dlgradient(loss,EncoderNet.Learnables);

end

function y = sigmoid(x)
y = 1./(1+exp(-x));
end

function y = softplus(x)
y = max(x,0) + log(1+exp(-abs(x)));
end

function grad = clipGrad(grad,maxNorm)

if istable(grad)

    total = 0;

    for k = 1:size(grad,1)

        g = grad.Value{k};

        total = total + ...
            sum(extractdata(g).^2,"all");

    end

    total = sqrt(total);

    scale = ...
        min(1,...
        maxNorm/(total+1e-8));

    for k = 1:size(grad,1)

        grad.Value{k} = ...
            grad.Value{k} .* scale;

    end

else

    total = sqrt( ...
        sum(extractdata(grad).^2,"all"));

    scale = ...
        min(1,...
        maxNorm/(total+1e-8));

    grad = grad .* scale;

end

end
