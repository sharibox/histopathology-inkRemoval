#!/bin/bash/

#ORIGINAL_INK_DATA_FOLDER='48434_14_600983_RP_1J'
#IDENTIFIER='48434_1J_GB'

# =========================== LOAD DATA  =========================== #

#ORIGINAL_INK_DATA_FOLDER='33299_14_600957_RP_2L'
#IDENTIFIER='33299_2L_GB'

#ORIGINAL_INK_DATA_FOLDER='45374_16_601166_RP_4O'
#IDENTIFIER='45374_4O_GB'
#annotationStudy or originalFiles
SUBFOLDER=originalFiles



# Step 1: detect all tiles with ink (background or foreground or bot)
#DATA_FILES=/well/rittscher/projects/dataset-NS/annotationStudy/${ORIGINAL_INK_DATA_FOLDER}/
#RESULT_FOLDER=/well/rittscher/projects/dataset-NS/annotationStudy/ISBI2019_$IDENTIFIER/

# Large folder and different location:
ORIGINAL_INK_DATA_FOLDER='47502_16_601169_RP_6N'
IDENTIFIER='47502_6N_GB'

DATA_FILES=/well/rittscher/projects/dataset-NS/$SUBFOLDER/${ORIGINAL_INK_DATA_FOLDER}/
RESULT_FOLDER=/well/rittscher/projects/dataset-NS/$SUBFOLDER/ISBI2019_$IDENTIFIER/

`mkdir -p ${RESULT_FOLDER}`

#echo $RESULT_FOLDER

# =========================== DO STEP_WISE  =========================== #
# Classify ink vs non-ink
INK_CLASSIFY=1
# Make Background ink classification
BCKGND_INK_CLASSIFY=1
# -moveFiles 1
BCKGND_INK_RESTORE=1
# 3(b) Run darknet trained model
LIST_TEST_IMAGES=1
runLocalization=1
moveFilesNonInk=1
#Apply cycleGAN
applyCyleGAN=1
# ======================================================================== #

# below is good only for 6N, 6M and 48434_14_600983_RP_1J---> generalized and retrained using more data histology_binary_ISBI19-GB_2.h5
#CHECKPOINT_ALL_INK_CLASIFY=histology_binary_ISBI19-GB_1.h5

# =========================== BINARY: INK vs NO-INK  =========================== #
CHECKPOINT_ALL_INK_CLASIFY=histology_binary_ISBI19-GB_2.h5
CODEBASE_DIR_BINARYCLASSIFIER=/users/rittscher/sharib/endo2Class_Keras/pythonScripts
if (( $INK_CLASSIFY == 1 ))
then
module load cuda/9.0
source activate TFPytorchGPU
python $CODEBASE_DIR_BINARYCLASSIFIER/inkImage_classify.py -input_dir $DATA_FILES -result_dir ${RESULT_FOLDER} -checkpoint ${CODEBASE_DIR_BINARYCLASSIFIER}/${CHECKPOINT_ALL_INK_CLASIFY} -moveImages 0

fi
# ======================================================================== #

# =========================== BINARY: ForeGND vs BCKGND  =========================== #
# Step 2: separate only background ink from the list
ORIGINAL_FILES=$RESULT_FOLDER
RESULT_DIR_BCKGND=/well/rittscher/projects/dataset-NS/$SUBFOLDER/ISBI2019_bckgndInkOnly_${IDENTIFIER}/

#CHECKPOINT_BCKGND=backgroundInk-new1.h5
CHECKPOINT_BCKGND=histology_binary_ISBI19_bckGnd-2.h5
if (( $BCKGND_INK_CLASSIFY == 1 ))
then
module load cuda/9.0
source activate TFPytorchGPU
`mkdir -p ${RESULT_DIR_BCKGND}`
python $CODEBASE_DIR_BINARYCLASSIFIER/inkImage_classify.py -input_dir ${ORIGINAL_FILES} -result_dir ${RESULT_DIR_BCKGND} -checkpoint ${CODEBASE_DIR_BINARYCLASSIFIER}/$CHECKPOINT_BCKGND -moveImages 1
fi
# ======================================================================== #

# =========================== BINARY: COPY BCKGND  =========================== #
PARENT_FOLDER=/well/rittscher/projects/dataset-NS
RESULT_RESTORED=/well/rittscher/projects/dataset-NS/$SUBFOLDER/ISBI2019_${IDENTIFIER}_restored
#echo ${RESULT_RESTORED}
SAMPLE_BLANK_IMAGE='33299_14_600957_RP_2L-clean.jpg'
# Step 2b: replace the colored tiles with sample background image
if (( $BCKGND_INK_RESTORE == 1 ))
then
    `mkdir -p ${RESULT_RESTORED}`
    for imageFile in `ls $RESULT_DIR_BCKGND |grep '.jpg'`; do

        echo $imageFile
        `cp   $PARENT_FOLDER/$SAMPLE_BLANK_IMAGE $RESULT_RESTORED/$imageFile`

    done
fi
# ======================================================================== #

# =========================== BINARY: YOLO DETECTION  =========================== #
# Step 3: Object localization and detection (2 class: ink and cluster) : threshold at 0.05
# 3(a) Make list of images for localization it does not exist

LIST_IMAGE_NAME=histoInkImagesClassify_ISBI19_${IDENTIFIER}'.txt'
#ORIGINAL_FILES=/well/rittscher/projects/dataset-NS/annotationStudy/ISBI2019_${IDENTIFIER}
ORIGINAL_FILES=/well/rittscher/projects/dataset-NS/$SUBFOLDER/ISBI2019_${IDENTIFIER}
if (( $LIST_TEST_IMAGES == 1 ))
then
    `rm ${ORIGINAL_FILES}/${LIST_IMAGE_NAME}`
    ext='.jpg'
    j=0
    for i in `ls ${ORIGINAL_FILES} | grep $ext`; do
        #echo $i
        echo ${ORIGINAL_FILES}/$i >> ${ORIGINAL_FILES}/${LIST_IMAGE_NAME}
	 	
       j=$((j+1))

    done
fi

#YOLO
CHECKPOINT=yolo-histology_6000.weights
DARKNET_DETECTION_FOLDER=/well/rittscher/projects/detection_histology/yoloV3_Alex/darknet
ORIG_DARKNET=/well/rittscher/projects/detection_histology/darknet
ORIGINAL_FILES=/well/rittscher/projects/dataset-NS/$SUBFOLDER/ISBI2019_$IDENTIFIER
OUTPUT_LOCALIZATION_TXTFILE=Yolo_histoInkImagesClassify_ISBI19_$IDENTIFIER.txt

if (( $runLocalization == 1 ))
then
#`rm ${ORIGINAL_FILES}/$OUTPUT_LOCALIZATION_TXTFILE`
    ${DARKNET_DETECTION_FOLDER}/darknet detector test ${ORIG_DARKNET}/cfg/histo.data ${ORIG_DARKNET}/cfg/yolo-histology.cfg ${ORIG_DARKNET}/backup/$CHECKPOINT -thresh 0.05 -dont_show -ext_output < ${ORIGINAL_FILES}/${LIST_IMAGE_NAME} > ${ORIGINAL_FILES}/$OUTPUT_LOCALIZATION_TXTFILE
fi
# ======================================================================== #

# =========================== BINARY: CYCLEGAN correction  =========================== #
# Step 4: Refine non-ink detected image tiles in Step 3 and save it in a restored Image folder
txtFileWithDetections=${OUTPUT_LOCALIZATION_TXTFILE}
if (( $moveFilesNonInk == 1 ))
then
    python cropProcessPutBack.py --datalist $ORIGINAL_FILES/$txtFileWithDetections --result_dir $RESULT_RESTORED/
fi

# Step 5: Apply cycleGAN on the remaining full images (TODO: check 0: no cluster, 1: cluster)
# Here you should be on gpu and pytorch environment should be activated

#IDENTIFIER='45374_4O_GB' ==> 434 images
CYCLEGAN_FOLDER=/well/rittscher/users/sharib/development/pytorch-CycleGAN-and-pix2pix
RESULT_DIR_CYCLEGAN=/well/rittscher/projects/dataset-NS/$SUBFOLDER/ISBI2019_${IDENTIFIER}'_CycleGAN'
CHECKPOINT_FOLDER=checkpoints/
#CHECKPOINT_FOLDER=checkpoint_SPARSE
CHECKPOINT_FOLDER=checkpoint_DENSE/
count=$(find $ORIGINAL_FILES -maxdepth 1 -name '*.jpg' | wc -l)
echo $count
if (( $applyCyleGAN == 1 ))
then
    source deactivate TFPytorchGPU
    module load cuda/9.0
    .  ~/pytorch-v0.4.0-cuda8.0-py3.5-venv/bin/activate
    python $CYCLEGAN_FOLDER/test.py  --dataroot $ORIGINAL_FILES --model test --loadSize 1578 --fineSize 1578  --how_many $count --results_dir $RESULT_DIR_CYCLEGAN/ --checkpoints_dir $CYCLEGAN_FOLDER/$CHECKPOINT_FOLDER/
fi
# ======================================================================== #

# Step 6: Crop images with less ink areas and copy to the original image tiles
# Step 7: Stitch the cropped and restored regions on original tiles in ISBI2019_48434_1J_GB_restored                                                                
