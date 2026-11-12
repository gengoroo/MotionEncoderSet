function dydI = gradientMap(dlnet, dlImgs, softmaxName, classIdx)
    % Compute the gradient of a class score with respect to one or more input% images.dydI = dlarray(zeros(size(dlImgs)));
    for i=1:size(dlImgs,4)
        I = dlImgs(:,:,:,i);
        scores = predict(dlnet,I,'Outputs',{softmaxName});
        classScore = scores(classIdx);
        dydI(:,:,:,i) = dlgradient(classScore,I);
    end
end