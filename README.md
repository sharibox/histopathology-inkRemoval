# histopathology-inkRemoval



### Requirements (maybe more than listed here, checkout requirements.txt):

    - Linux/Unix only
    - TensorFlow 1.8 
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





## License

This software is covered by MIT License.
