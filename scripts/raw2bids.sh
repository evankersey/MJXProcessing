#!/bin/bash

Usage() {
    echo ""
    echo "Run this file as the very first step of processing MJX files"
    echo "Note: This code depends on MRIcroGL's dcm2niix."
    echo "Usage: bash raw2bids.sh <raw files folder> <BIDS folder> <options>"
    echo "Options:"
    echo "-NL: raw files are collected from NL"
    echo "-UTD: raw files are collected from UTD"
    echo "Please choose either one from the option"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage
[ "$2" = "" ] && Usage

# separating "subj" is to convert one subject at a time
raw_dir=$1
BIDS_dir=$2

# Checks variables above.
if [[ ! -d $raw_dir ]]; then
  echo "Exit 1. Raw data directory does not exist."
  exit 1
elif [[ ! -d $BIDS_dir ]]; then
  mkdir -p $BIDS_dir
else echo "Conversion started"
fi

# Follow different algorithms depending on options, -NL or -UTD
# NL team uses Philips (par + rec)
# UTD team uses Siemens (dcm series)

base_dir=$(echo $0 | sed "s#raw2bids\.sh##")
[[ $base_dir == "" ]] && base_dir=.
if [[ $3 = "-NL" ]]; then
	# Ryan's code
	# Written for Dutch data conversion.
	# NOTE: This was written for the structure given in DataNL/4_MRIdata.
	#       If new/future data comes in different format, this will break.

	# Main loop: Raw >> BIDS
	for subj in ${raw_dir}/*; do
  	subjID=$(echo $subj | sed -e "s#.*\/##" -e "s/sub-//")
  	# Store raw data directories into array and size into variable.
    num_raw_sess=0
		# Raw data must be in session folders (ie sub-1001/ses-01/*.{PAR,REC})
    if [[ -d $subj/ses-02 ]]; then
      num_raw_sess=2
    elif [[ -d $subj/ses-01 ]]; then
      num_raw_sess=1
		else
      echo "$subj missing a session folder."
		  break
		fi
		# Store pre-existing number of BIDS data directories.
		num_bids_sess=0
		if [[ -d ${BIDS_dir}/sub-${subjID} ]]; then
			for bids_ses in ${BIDS_dir}/sub-${subjID}/*; do
				(( num_bids_sess++ ))
			done
		fi
		# Setup subject and session BIDS directories.
		for ses in $(seq 1 ${num_raw_sess}); do
			mkdir -p ${BIDS_dir}/sub-${subjID}/ses-0${ses}
		done
		# Copy all data to BIDS format for new subject's sessions.
		start=$((num_bids_sess+1)) # Skip BIDS sessions that already exists.
		for ses in $(seq $start $num_raw_sess); do
			# Convert anatomical data to BIDS
			anat_check=$(ls -1 $subj/ses-0$ses/ | grep ".*T1w.*\.PAR" | head -n 1)
			if [[ -n $anat_check ]]; then
				mkdir -p ${BIDS_dir}/sub-${subjID}/ses-0${ses}/anat
			fi

			for anat in $subj/ses-0$ses/*T1w*.PAR; do
				acq=$(echo $anat | sed -e "s/.*acq-//" -e "s/_.*//")
				$base_dir/dcm2niix_NL -p n -o ${BIDS_dir}/sub-${subjID}/ses-0${ses}/anat \
				-f sub-${subjID}_ses-0${ses}_T1w ${anat} > /dev/null 2>&1
			done
			# Convert functional data and fmaps to BIDS
			func_check=$(ls -1 $subj/ses-0${ses}/ | grep ".*task.*\.PAR" | head -n 1)
			if [[ -n $func_check ]]; then
				mkdir -p ${BIDS_dir}/sub-${subjID}/ses-0${ses}/func
			fi
			func_fmap_check=$(ls -1 $subj/ses-0${ses}/ | grep ".*task.*topup.*\.PAR" | head -n 1)
			if [[ -n $func_fmap_check ]]; then
				mkdir -p ${BIDS_dir}/sub-${subjID}/ses-0${ses}/fmap
			fi

			for func in $subj/ses-0$ses/*task*.PAR; do
				task=$(echo $func | sed -e "s/.*_task-//" -e "s/_.*//" | tr '[:lower:]' '[:upper:]')
				[[ $task == RESTINGSTATE ]] && task=REST
				is_topup=$(echo $func | grep topup)
				if [[ -z $is_topup && $task == CUE ]]; then
					run=$(echo $func | sed -e "s/.*_run-//" -e "s/_.*//")
					$base_dir/dcm2niix_NL -p n -o ${BIDS_dir}/sub-${subjID}/ses-0${ses}/func \
					-f sub-${subjID}_ses-0${ses}_task-${task}RUN${run}_bold ${func} \
					> /dev/null 2>&1
				elif [[ -z $is_topup ]]; then
					$base_dir/dcm2niix_NL -p n -o ${BIDS_dir}/sub-${subjID}/ses-0${ses}/func \
					-f sub-${subjID}_ses-0${ses}_task-${task}_bold ${func} > /dev/null 2>&1
				elif [[ -n $is_topup && $task == CUE ]]; then
					run=$(echo $func | sed -e "s/.*_run-//" -e "s/_.*//")
					$base_dir/dcm2niix_NL -p n -o ${BIDS_dir}/sub-${subjID}/ses-0${ses}/fmap \
					-f sub-${subjID}_ses-0${ses}_task-${task}RUN${run}_epi ${func} > /dev/null 2>&1 && \
          sed -i "s/\}/\t\"IntendedFor\": \"ses-0${ses}\/func\/sub-${subjID}_ses-0${ses}_task-${task}RUN${run}_bold.nii\"\n\}/" \
          ${BIDS_dir}/sub-${subjID}/ses-0${ses}/fmap/sub-${subjID}_ses-0${ses}_task-${task}RUN${run}_epi.json &
				elif [[ -n $is_topup ]]; then
					$base_dir/dcm2niix_NL -p n -o ${BIDS_dir}/sub-${subjID}/ses-0${ses}/fmap \
					-f sub-${subjID}_ses-0${ses}_task-${task}_epi ${func} > /dev/null 2>&1  && \
          sed -i "s/\}/\t\"IntendedFor\": \"ses-0${ses}\/func\/sub-${subjID}_ses-0${ses}_task-${task}_bold.nii\"\n\}/" \
          ${BIDS_dir}/sub-${subjID}/ses-0${ses}/fmap/sub-${subjID}_ses-0${ses}_task-${task}_epi.json &
				fi
			done
			# Convert diffusion data to BIDS
			dwi_check=$(ls -1 $subj/ses-0${ses}/ | grep ".*_dwi.*\.PAR" | head -n 1)
			if [[ -n $dwi_check ]]; then
				mkdir -p ${BIDS_dir}/sub-${subjID}/ses-0${ses}/dwi
			fi
			dwi_fmap_check=$(ls -1 $subj/ses-0${ses}/ | grep ".*dir-dwi.*\.PAR" | head -n 1)
			if [[ -n $dwi_fmap_check ]]; then
				mkdir -p ${BIDS_dir}/sub-${subjID}/ses-0${ses}/fmap
			fi

			for dwi in $subj/ses-0${ses}/*dwi*.PAR; do
				is_topup=$(echo $dwi | grep topup)
				if [[ -z $is_topup ]]; then
					$base_dir/dcm2niix_NL -p n -o ${BIDS_dir}/sub-${subjID}/ses-0${ses}/dwi \
					-f sub-${subjID}_ses-0${ses}_acq-DTIMPS129_dwi ${dwi} > /dev/null 2>&1 &
				elif [[ -n $is_topup ]]; then
					$base_dir/dcm2niix_NL -p n -o ${BIDS_dir}/sub-${subjID}/ses-0${ses}/fmap \
					-f sub-${subjID}_ses-0${ses}_acq-DTI_epi ${dwi} > /dev/null 2>&1 && \
          sed -i "s/\}/\t\"IntendedFor\": \"ses-0${ses}\/dwi\/sub-${subjID}_ses-0${ses}_acq-DTIMPS129_dwi.nii\"\n\}/" \
          ${BIDS_dir}/sub-${subjID}/ses-0${ses}/fmap/sub-${subjID}_ses-0${ses}_acq-DTI_epi.json &
				fi
			done
		done
    wait
	done

elif [[ $3 = "-UTD" ]]; then

	# Hye's code
	# assign repeated string as the target of removal
	export subj=$(ls $raw_dir); echo $subj;

	for s in $subj
	do

		mkdir -p $BIDS_dir/sub-$s
		echo "Conversion for subject $s"
		echo "-------------------------"

	   # based on "Study date", determine if this is session 1 (first) or 2 (second)
		export sess_list=$(ls $raw_dir/$s | sed "s/ /\n/g" | sort); echo $sess_list;
		export k=0;
		for i in $sess_list; do StudyArray[k]=$i; k=$((k))+1; done;

    # in case of scan failure resulting in > 2 sessions
    if [[ ${#StudyArray[@]} -gt 2 ]]; then
      echo "More than two sessions found. Skipping sub-$s..."
      break
    fi

    if [[ -z $(echo ${StudyArray[1]}) && ! -d $BIDS_dir/sub-$s/ses-01 && -z $(echo ${StudyArray[2]}) && ! -d $BIDS_dir/sub-$s/ses-02 ]]; then
      bash Conversion.sh ${raw_dir} ${BIDS_dir} ${s} ses-01 ${StudyArray[0]}
      bash Conversion.sh ${raw_dir} ${BIDS_dir} ${s} ses-02 ${StudyArray[01}
    elif [[ -z $(echo ${StudyArray[1]}) && ! -d $BIDS_dir/sub-$s/ses-01 ]]; then
			bash Conversion.sh ${raw_dir} ${BIDS_dir} ${s} ses-01 ${StudyArray[0]}
		elif [[ -z $(echo ${StudyArray[2]}) && ! -d $BIDS_dir/sub-$s/ses-02 ]]; then
			bash Conversion.sh ${raw_dir} ${BIDS_dir} ${s} ses-02 ${StudyArray[1]}
		fi

		unset StudyArray;
		unset sess_list;

	done

else
	echo "Must choose between -NL or -UTD for the third argument"
	exit 1
fi
