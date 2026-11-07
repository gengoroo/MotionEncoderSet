function mask = createOhtsuMask(CCones_var)


    I = CCones_var(:,:,ii);
    level = graythresh(I);
    Mask(:,:,ii) = imbinarize(I,level);

end