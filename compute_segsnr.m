

%~~~~~~~~~~~~~~~K~ Data preparation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
%All the Acoustic data files for training are located here:
files_folder = 'C:\Users\karinb\Desktop\ACLP\MatlabScripts\text\toKaldi_SNR\train\H\';
%Input Audio files  
audio_folder = 'C:\data\audio\train\H';
%Input .tab files
%tab_folder = 'C:\data\audio\train\tab';
% Preper files:
[segments_file, audioFiles, SNR_segments_file, wav_scp_file] = preperFiles (files_folder, audio_folder);

%~~~~~~~~~~~~~~~K~ Read sampled audio data~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
[audio, Fs, speakerID] = createSampledAudio(wav_scp_file, audio_folder);  

%~~~K~ create an array of speaker IDs from wav.scp file that matches speaker IDs from segments file
[lookup_table_audio, numOfSegments_vec, begin_sample_vec, end_sample_vec,begin_sample_Noise_vec, end_sample_Noise_vec,  lines] = matchAudioFiles (segments_file, speakerID, Fs);

%~~~~~~~~~~~~~~~K~ Initializtion ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sum_of_j = 0;  j=1;   reminder = 0;  index = 1; zero = 0; sum_small_segments = 0; counts = 0;  speaker_name_part_1 = 0; speaker_name_part_2 = 0; NotSpeechCount = 0; NotTransCount = 0;
SNR = zeros(1,length(begin_sample_vec));
edge_cases_vec = []; segments_length = [];

%~~~~~~~~~~~~K~ calc SNR for each segment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%~K~ go over all audio files (282)
for i=1:length(numOfSegments_vec)
    audio_stream = audio{lookup_table_audio(i)};

    if (numOfSegments_vec(lookup_table_audio(i))==0)
        continue;
    end
    %~K~ go over all segments in each audio file
    for k=1:numOfSegments_vec(lookup_table_audio(i))
        % get signals
        signal = audio_stream(round(begin_sample_vec(j)):round(end_sample_vec(j)));
        %if segment is NS or NT or RX or (no NS before or after) - skip SNR calculation
        if ((begin_sample_Noise_vec(j)==0)&&(end_sample_Noise_vec(j)==0)) %NS (not speech)
            NotSpeechCount = NotSpeechCount + 1;
            SNR(j) = 100; 
            j=j+1;
            continue;
        end
        if (begin_sample_Noise_vec(j) > end_sample_Noise_vec(j)) % no NS before or after - remove from training set
            NotTransCount = NotTransCount + 1;
            SNR(j) = -100; 
            j=j+1;
            continue;
        end
        % calc noise
        potential_noise = audio_stream(round(begin_sample_Noise_vec(j)):round(end_sample_Noise_vec(j)));

        L = length(signal);
        L_noise = length(potential_noise);       
        % check if energy of noise is smaller than signal to make sure
        % it's not channel interrupt:
        % check if it is a noise or it is a too short segment
        
        noise = potential_noise;
        % call segmental SNR - ~K~ calc SNR  
        SNR(j) = segSNR(signal, noise);
        %~K~ set each segment length value to array of segments lengths
        segments_length(index) = L;
        % remove shortest segments
        %if (SNR(j) < 0)
        %    SNR(j) = 0;
        %end
        if (segments_length(index)<6881) %5761 value of 5% segment lenght (6881 - 10%)
          SNR(j) = -100;
        end
        index = index + 1;
        if (j==sum(numOfSegments_vec(lookup_table_audio(1:i)))-1)
            %~K~ deal with the end of each audio file
            sum_of_j = sum_of_j + 1;
            signal = audio_stream(round(begin_sample_vec(j+1):round(end_sample_vec(j+1))));

            SNR(k+reminder+1) = segSNR(signal, potential_noise);
            j=j+1;
            break;
            
        end
        j=j+1;
    end
    j=j+1;
    reminder = reminder+numOfSegments_vec(lookup_table_audio(i));
end
%~~~~~~~~~~~~K~ calc SNR for each segment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


%~~~~~~~~~~~~K~ plot segments length histogram~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%hist = histogram(SNR);
% count each bin value
%counts = hist.Values;
% sort segment length
sort_segments_length = sort(segments_length);
sort_SNR = sort(SNR);
Seg_val = prctile(sort_segments_length, 10);
%~~~~~~~~~~~~K~ remove 5% of the shortest segments~~~~~~~~~~~~~~~~~~~~~~~~


%~~~~~~~~~~~~K~create output segments file (after discarding 10% lowest SNR)- segments2~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
snrPercentage = 10; % set the SNR percentage to discard
[segments2] = discardLowestSnr (lines, SNR_segments_file, snrPercentage, SNR, segments_file, files_folder);


