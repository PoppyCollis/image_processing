% Image Processing Lab Project
% CandNo: 244106

%% FULL PIPELINE

colours = colourMatrix('images2/rot_3.png');

%%

%colour matrix final function
function [colour_matrix] = colourMatrix(filename)
    
    % convert image to LAB space and convert to double 
    image_db = loadImage(filename);
    % find the circle coordinates 
    circle_centres = findCircles(image_db);
    % undistort the image
    corrected = correctImage(circle_centres, image_db);
    % find the colours of each square 
    colour_matrix = findColours(corrected)

end

% load in image and convert to double and LAB space
function [image_doub] = loadImage(filename) 
    rgb = imread(filename);
    % create filter
    C = makecform('srgb2lab');
    % apply this filter to convert to LAB space
    lab = applycform(rgb, C);
    % convert image to a type double
    image_doub = lab2double(lab);
end

% find the coordinates of the four circles in the image
function [circleCoordinates] = findCircles(image_double)
       
    % remove noise with a mean filter
    image_dn = denoise(image_double);
    
    % get just the L-channel
    L = image_dn(:,:,1);
    figure(1), imshow(L, [])
    
    % erode and then dilate the image
    im1=imerode(L,ones(7));
    im2=imdilate(im1,ones(7));
    % threshold 
    im3 = im2>30;
    %figure(2), imshow(im3, []);
    bw = imcomplement(im3);
    
    % filter to return image with only 4 largest area objects present
    BW2 = bwareafilt(bw,4);
    %figure(3), imshow(BW2);
    
    % get the centre coordinates of these objects (should be the circles)
    s = regionprops(BW2,'centroid');
    centroids = cat(1,s.Centroid);
    %imshow(BW2)
    %hold on
    %plot(centroids(:,1),centroids(:,2),'b*');
    %hold off
    circleCoordinates = centroids
   
end

% applies a mean filter to remove noise in the image
function [denoised_img] = denoise(image)
    filter=fspecial('average',6);
    denoised_img=imfilter(image,filter);
end

% this function corrects the image for any distortion
function [corrected] = correctImage(circleCoordinates, image)
    % use noise_1 points as the standard 'registered' image
    % this is because we know we can find these undistorted points correctly
    I = loadImage('images2/noise_1.png');
    standard_centroids = findCircles(I);
    % create an image from coordinates
    standard_centres = im2double(standard_centroids);

    % find the circle coordinates for distorted image
    current_centroids = findCircles(image);
    % create an image from coordinates
    current_centres = im2double(current_centroids);
    
    % find the transform matrix using these two sparse images
    tform = fitgeotrans(current_centres,standard_centres,'projective');
    
    % correct the distorted image using the transform matrix found above
    corrected = imwarp(image,tform,'OutputView',imref2d(size(I)));
    %figure(1), imshowpair(corrected,I(:,:,1));
    %figure(2), imshow(corrected); 
    
end

% this function takes in a double image array (image) and returns colours
function [colours] = findColours(image)
   
    % denoise the image by applying an average filter
    image_dn = denoise(image);
    %imshow(image_dn, []);
    
    % Extract L, a and b into separate arrays
    L = image_dn(:,:,1);
    A = image_dn(:,:,2);
    B = image_dn(:,:,3);
    
    % calculate the centroids of squares from an undistorted image
    undistorted_image = 'images2/noise_1.png'
    square_c = findSquares(undistorted_image);
    
    % iterate through the list of square centres and get colour of pixel
    % coordinates
    colour_list = cell(4,4);
    sz = size(square_c);
    for i=1: sz(1)
        coord = square_c(i,:);
        colour = getColour(A, B, uint16(coord(1)),uint16(coord(2)));
        colour_list{i} = colour;
    end
    
    % flip the array
    colours = flip(colour_list);
    
end

% this function automatically finds the centre coordinates of the squares
% from an undistorted image
function [square_centres] = findSquares(filename) 
    
    % denoise the image
    rgb = imread('images2/noise_1.png');
    %figure, imshow(rgb);
    filter=fspecial('average',2);
    image_dn = imfilter(rgb,filter);
    %figure(1), imshow(image_dn);
    
    % high threshold to get all coloured objects as black
    BW = im2bw(image_dn, 0.99);
    figure(2), imshow(BW);
    % heavy dilation to remove noise and circles, leaving only squares
    im1=imdilate(BW,ones(60));
    figure(3), imshow(im1);
    
    % invert image
    bw2 = imcomplement(im1);
    %figure(4), imshow(bw2);

    % find component objects
    CC=bwconncomp(bw2)

    % plot the centroids of the objects
    s = regionprops(bw2,'centroid');
    centroids = cat(1,s.Centroid);
    square_centres = centroids
end

% this function retrieves the colours of the squares
function [colour] = getColour(A, B, coord_1, coord_2)
    % get a, b channels
    
    % get individual pixel from coord
    a = A(coord_1,coord_2);
    b = B(coord_1,coord_2);
    
    % thresholds for colour categories manually set
    if b < -40
        colour = 'b';
    else
        if a < -30
            colour = 'g';
        elseif a > 20
            colour = 'r';
        else colour = 'y';
        end
    end
end

