function Model = cortical_som_train(MOV_input,pn_save)

%% =====================================================
% Encoder-only cortical representation learner
% MATLAB R2024a
% RTX3060 6GB compatible
%% =====================================================

rng(1)

%% PARAMETERS

latentDim = 64;

numEpoch = 50;

rho = 0.10;

betaKL = 0.01;

gammaW = 1e-4;

lambdaVar = 0.1;

lrEncoder = 1e-3;
lrAlpha   = 2e-4;
lrW       = 5e-5;

%% =====================================================
% Resize
%% =====================================================

fprintf('Resizing movies...\n')
nMovData = size(MOV_input,4);
nFrames = size(MOV_input,3);
for k = 1:nMovData

    MOV_adjust{k} = single( ...
        imresize3( ...
        MOV_input(:,:,:,k), ...
        [128 128 nFrames]));

end

%% =====================================================
% Encoder
%% =====================================================

layers = [

image3dInputLayer( ...
    [128 128 nFrames 1], ...
    Normalization="none")

convolution3dLayer(3,16,...
    Padding="same")
batchNormalizationLayer
reluLayer

maxPooling3dLayer(2,...
    Stride=2)

convolution3dLayer(3,32,...
    Padding="same")
batchNormalizationLayer
reluLayer

maxPooling3dLayer(2,...
    Stride=2)

convolution3dLayer(3,64,...
    Padding="same")
batchNormalizationLayer
reluLayer

convolution3dLayer(1,8,...
    Padding="same")

globalAveragePooling3dLayer

fullyConnectedLayer(latentDim)

];

EncoderNet = dlnetwork(layerGraph(layers));

%% =====================================================
% Learnable inhibition
%% =====================================================

alphaRaw = dlarray( ...
    zeros(latentDim,1,'single'));

Wraw = dlarray( ...
    single(0.01*randn(latentDim)));

mask = ones(latentDim,'single');
mask(1:65:end)=0;
mask = dlarray(mask);

%% =====================================================
% Adam states
%% =====================================================

avgE = [];
avgSqE = [];

avgA = [];
avgSqA = [];

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

for epoch = 1:numEpoch

    betaKL_now = ...
        betaKL * min(epoch/20,1);

    epochLoss = [];

    for iMovie = 1:numel(MOV_adjust)

        iteration = iteration + 1;

        X = MOV_adjust{iMovie};

        X = reshape(X,...
            128,128,nFrames,1);

        X = dlarray(X,"SSSC");

        [loss,...
         KLloss,...
         Wloss,...
         varLoss,...
         activeFraction,...
         gradE,...
         gradA,...
         gradW] = ...
         dlfeval( ...
         @modelGradients,...
         EncoderNet,...
         X,...
         alphaRaw,...
         Wraw,...
         mask,...
         rho,...
         betaKL_now,...
         gammaW,...
         lambdaVar);

        gradE = clipGrad(gradE,5);
        gradA = clipGrad(gradA,0.5);
        gradW = clipGrad(gradW,0.5);

        [EncoderNet,...
         avgE,...
         avgSqE] = ...
         adamupdate( ...
         EncoderNet,...
         gradE,...
         avgE,...
         avgSqE,...
         iteration,...
         lrEncoder);

        [alphaRaw,...
         avgA,...
         avgSqA] = ...
         adamupdate( ...
         alphaRaw,...
         gradA,...
         avgA,...
         avgSqA,...
         iteration,...
         lrAlpha);

        [Wraw,...
         avgW,...
         avgSqW] = ...
         adamupdate( ...
         Wraw,...
         gradW,...
         avgW,...
         avgSqW,...
         iteration,...
         lrW);

        epochLoss(end+1) = ...
            gather(extractdata(loss));

    end

    alpha = 0.5*sigmoid(alphaRaw);

    Winh = softplus(Wraw).*mask;

    History.loss(epoch) = ...
        mean(epochLoss);

    History.KL(epoch) = ...
        gather(extractdata(KLloss));

    History.Wloss(epoch) = ...
        gather(extractdata(Wloss));

    History.VarLoss(epoch)= ...
        gather(extractdata(varLoss));

    History.active(epoch)= ...
        gather(extractdata(activeFraction));

    History.alphaMean(epoch)= ...
        gather(extractdata(mean(alpha)));

    History.Wmean(epoch)= ...
        gather(extractdata(mean(Winh,"all")));

    fprintf( ...
        ['Epoch %03d | ' ...
         'Loss %.4f | ' ...
         'KL %.4f | ' ...
         'Var %.4f | ' ...
         'Active %.3f\n'],...
         epoch,...
         History.loss(epoch),...
         History.KL(epoch),...
         History.VarLoss(epoch),...
         History.active(epoch));

end

%% =====================================================
% Embedding
%% =====================================================

Embedding = zeros( ...
    numel(MOV_adjust), ...
    latentDim);

for iMovie = 1:numel(MOV_adjust)

    X = MOV_adjust{iMovie};

    X = reshape(X,...
        128,128,nFrames,1);

    X = dlarray(X,"SSSC");

    Z = forward(EncoderNet,X);

    alpha = 0.5*sigmoid(alphaRaw);

    Winh = softplus(Wraw).*mask;

    Winh = ...
        Winh ./ ...
        max(sum(Winh,2),1);

    rowSum = sum(Winh,2) + 1e-6;

    Winh = Winh ./ rowSum;
    
    Zu = stripdims(Z);

    alpha = stripdims(alpha);
    
    Winh = stripdims(Winh);
    
    inh = Winh * Zu;
    
    Zinh = Zu - 0.1 .* alpha .* inh;
    
    Zinh = max(Zinh,0);
    
    Zinh = max(Zinh,0);

    Zinh = max(Zinh,0);

    Embedding(iMovie,:) = ...
        gather(extractdata(Zinh(:)))';

end

%% =====================================================
% SOM
%% =====================================================

fprintf('Training SOM...\n')

netSOM = selforgmap([8 8]);

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

Model.alpha = ...
    gather(extractdata(alpha));

Model.Winh = ...
    gather(extractdata(Winh));

Model.SOM = netSOM;

Model.History = History;

save([pn_save '\CorticalEncoder.mat'],'Model','-v7.3');

%% =====================================================
% Plot
%% =====================================================

figure

subplot(2,2,1)
plot(History.loss)
title('Loss')

subplot(2,2,2)
plot(History.active)
title('Active Fraction')

subplot(2,2,3)
imagesc(reshape(Model.alpha,8,8))
axis image
colorbar
title('Alpha Map')

subplot(2,2,4)
imagesc(Model.Winh)
colorbar
title('Winh')

end

%% =====================================================
function [loss,KLloss,Wloss,varLoss,...
          activeFraction,...
          gradE,gradA,gradW] ...
    = modelGradients( ...
        EncoderNet,...
        X,...
        alphaRaw,...
        Wraw,...
        mask,...
        rho,...
        betaKL,...
        gammaW,...
        lambdaVar)

%% =====================================================
% Encoder
%% =====================================================

Z = forward(EncoderNet,X);

% Z : [64 x 1]

%% =====================================================
% Learnable inhibition
%% =====================================================

alpha = 0.5 .* sigmoid(alphaRaw);

Winh = softplus(Wraw) .* mask;

% Row normalization
rowSum = sum(Winh,2) + 1e-6;

Winh = Winh ./ rowSum;

%% =====================================================
% Lateral inhibition
%% =====================================================

Zu = stripdims(Z);

alpha = stripdims(alpha);

Winh = stripdims(Winh);

inh = Winh * Zu;

Zinh = Zu - 0.1 .* alpha .* inh;

Zinh = max(Zinh,0);

%% =====================================================
% KL sparsity
%% =====================================================

rhoHat = mean(Zinh,2);

rhoHat = max(rhoHat,1e-6);
rhoHat = min(rhoHat,1-1e-6);

KLloss = sum( ...
      rho .* log(rho./rhoHat) ...
    + (1-rho).*log((1-rho)./(1-rhoHat)), ...
    "all");

%% =====================================================
% Inhibitory weight penalty
%% =====================================================

Wloss = mean(abs(Winh),"all");

%% =====================================================
% Variance preservation
%% =====================================================

meanZ = mean(Zinh,2);

varZ = mean((Zinh-meanZ).^2,2);

varLoss = mean(varZ,"all");

%% =====================================================
% Activity monitor
%% =====================================================

activeFraction = ...
    mean(single(Zinh>0),"all");

%% =====================================================
% Total loss
%% =====================================================

loss = ...
      betaKL * KLloss ...
    + gammaW * Wloss ...
    - lambdaVar * varLoss;

%% =====================================================
% Gradients
%% =====================================================

[gradE,...
 gradA,...
 gradW] = dlgradient( ...
    loss,...
    EncoderNet.Learnables,...
    alphaRaw,...
    Wraw);

end

function y = sigmoid(x)
y = 1./(1+exp(-x));
end

function y = softplus(x)
y = log(1+exp(x));
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
            grad.Value{k}*scale;

    end

end

end