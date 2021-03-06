# histopathology-inkRemoval

(working on removing explicit PATH setting...)

``parts of codes are borrowed from CycleGAN for foreground ink removal``

### Requirements (maybe more than listed here, checkout requirements.txt):

- Linux/Unix only
- Keras with TensorFlow backend
- pyTorch 0.4 
- CUDA 8.0/9.0
- Compiled Darknet for detection [here](https://github.com/AlexeyAB/darknet) or simply do
  
         -  ``git clone https://github.com/AlexeyAB/darknet.git``
         -  cd darknet 
         -  make (check for necessary settings [here](https://github.com/AlexeyAB/darknet))
         -  make a soft link ln -s $FULL_PATH/darknet $DIR_THIS_REPO/darknet/darknet
          
          
### How to use it?

- Go to checkpoints folder and download test images and provided checkpoints
- Run: test_ink_removal.py in code folder (see parameters inside the code)

### How to use the entire pipeline?

- Make sure you have a folder with image tiles
- Make sure you have all the checkpoints needed
- Go to scripts folder and edit ``writeTestDataResult.sh`` for `PATHS`
- If all goes well then you should be able to run the entire pipeline

### Evaluation

Check the folder [here](https://github.com/sharibox/histopathology-inkRemoval/tree/master/evaluation)

### Test data 

[Download here](https://s3.amazonaws.com/histologyinkremoval/histo_ink_removal.zip)

    Note: Please change the data directory in scripts/writeTestDataResult.sh to '`pwd`/histo_ink_removal'

## License

This software is covered by MIT License.

## Cite
Ink removal from histopathology whole slide images by combining classification, detection and image generation models. Ali et al. 2019 IEEE 16th International Symposium on Biomedical Imaging (ISBI 2019)
