#!/bin/bash

# Conversion function
# assign repeated string as the target of removal
# bash Conversion.sh ${raw_dir} ${BIDS_dir} ${i} ses-01 ${StudyArray[0]}

raw_dir=$1
bids_dir=$2
subj=sub-$3
sess=$4
studycode=$5

CURRENT=$(pwd);
export remove=$raw_dir/$3/$studycode/

# "sed" takes out repeated part, "cut" takes out prefix
export modality=$(find $raw_dir/$3/$studycode -name AX* | sed "s|$remove||g" | cut -d_ -f2-)

# by sorting, older files are automatically ignored and the latest files are saved as valid ones
export modality=$(echo $modality | sed "s/ /\n/g" | sort)
echo $modality
# now modality has the list of MR folders

# assign sessions by modality
export task_list=$(for i1 in $modality; do echo $i1 | grep BOLD | cut -c 6- | rev | cut -c 6- | rev | sort; done)
export k=0;
for i2 in $task_list; do TaskArray[k]=$i2; k=$((k))+1; done

export t1="UTD_MPR" # we are NOT using DUTCH FLASH due to quality issues

export dti_list=$(for j1 in $modality; do echo $j1 | grep DTI | rev | cut -c 10- | rev | sort; done)
export k=0;
for j2 in $dti_list; do DTIArray[k]=$j2; k=$((k))+1; done

mkdir -p $bids_dir/$subj/$sess/
mkdir $bids_dir/$subj/$sess/anat
mkdir $bids_dir/$subj/$sess/func
mkdir $bids_dir/$subj/$sess/fmap
mkdir $bids_dir/$subj/$sess/dwi

# main loop of dcm2niix
export k1=0; export k2=0;
for mr in $modality
do
	# T1	
	if [[ $(echo $mr | grep $t1) ]];
	then
		echo $mr; echo "---"
		./dcm2niix -o $bids_dir/$subj/$sess/anat/ -f ${subj}_${sess}_T1w -w 1 $raw_dir/$3/$studycode/AX_$mr/
	
	# FMRI, non-TOPUP
	elif [[ $(echo $mr | grep ${TaskArray[k1]}) ]] && [[ -z $(echo $mr | grep TOP_UP) ]];
	then
		echo $mr; echo "---"
		export name=$(echo ${TaskArray[k1]} | sed "s/_//g");
		./dcm2niix -o $bids_dir/$subj/$sess/func/ -f ${subj}_${sess}_task-${name}_bold -w 1 $raw_dir/$3/$studycode/AX_$mr/
		k1=$((k1))+1;
	
	# FMRI, TOPUP
	elif [[ $(echo $mr | grep ${TaskArray[k1]}) ]] && [[ $(echo $mr | grep TOP_UP) ]];
	then
		echo $mr; echo "---"
		export name=$(echo ${TaskArray[k1]} | sed "s/_//g");
		export trunc_name=$(echo $name | rev | cut -c 6- | rev);
		export TARGET="$sess/func/${subj}_${sess}_task-${trunc_name}_bold.nii"; # original fmri file
		./dcm2niix -o $bids_dir/$subj/$sess/fmap/ -f ${subj}_${sess}_task-${trunc_name}_epi -w 1 $raw_dir/$3/$studycode/AX_$mr/
		k1=$((k1))+1;
		
		cd $bids_dir/$subj/$sess/fmap/
		cat ${subj}_${sess}_task-${trunc_name}_epi.json | sed -z '$s/\n}/,\n\t"IntendedFor": "xxx"\n}/' | sed "s|xxx|$TARGET|g" > test.json
		mv test.json ./${subj}_${sess}_task-${trunc_name}_epi.json
		cd $CURRENT;
		
	# DTI, non-TOPUP
	elif [[ $(echo $mr | grep ${DTIArray[k2]}) ]] && [[ -z $(echo $mr | grep TOP_UP) ]];
	then
		echo $mr; echo "---"
		export name=$(echo ${DTIArray[k2]} | sed "s/_//g"); export DTI_name=$name;
		./dcm2niix -o $bids_dir/$subj/$sess/dwi/ -f ${subj}_${sess}_acq-${name}_dwi -w 1 $raw_dir/$3/$studycode/AX_$mr/
		k2=$((k2))+1;
		
	# DTI, TOPUP
	elif [[ $(echo $mr | grep ${DTIArray[k2]}) ]] && [[ $(echo $mr | grep TOP_UP) ]];
	then
		echo $mr; echo "---"
		export name=$(echo ${DTIArray[k2]} | sed "s/_//g");
		export trunc_name=$(echo $name | rev | cut -c 6- | rev);
		export TARGET="$sess/dwi/${subj}_${sess}_acq-DTIMPS129_dwi.nii"
		./dcm2niix -o $bids_dir/$subj/$sess/fmap/ -f ${subj}_${sess}_acq-${trunc_name}_epi -w 1 $raw_dir/$3/$studycode/AX_$mr/
		k2=$((k2))+1;
		
		cd $bids_dir/$subj/$sess/fmap/
		cat ${subj}_${sess}_acq-${trunc_name}_epi.json | sed -z '$s/\n}/,\n\t"IntendedFor": "xxx"\n}/' | sed "s|xxx|$TARGET|g" > test.json
		mv test.json ./${subj}_${sess}_acq-${trunc_name}_epi.json
		cd $CURRENT;
	fi
done
