function mapGB = guided_backprop(net, im, classIdx)

	dlImg = dlarray(single(im),'SSC');%To use automatic differentiation, convert the image of Laika to a dlarray.
	
	lgraph = layerGraph(net);
	lgraph = removeLayers(lgraph,lgraph.Layers(end).Name);%ネットワークは出力層を持ってはいけない。
	customRelu = CustomBackpropReluLayer();
    customRelu.BackpropMode = "guided-backprop";
    lgraphGB = replaceLayersOfType(lgraph, "nnet.cnn.layer.ReLULayer",customRelu);
	dlnetGB = dlnetwork(lgraphGB);
	
	softmaxName = 'softmax';
	dydIGB = dlfeval(@gradientMap,dlnetGB,dlImg,softmaxName,classIdx);%Compute gradient attribution map for the network using guided backpropagation.
    mapGB = sum(abs(extractdata(dydIGB)),3);
    mapGB = rescale(mapGB);
	cmap = [linspace(1,0,255)' linspace(1,0,255)' linspace(1,0,255)'];
	%imshow(mapGB, "Colormap", cmap);
    %title("Guided Backpropagation ("+ string(predClass) + ")");

end
