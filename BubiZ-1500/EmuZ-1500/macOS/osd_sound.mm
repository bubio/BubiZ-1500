/*
	Skelton for retropc emulator
	macOS port

	[ macOS OSD - sound (AVAudioEngine) ]
*/

#include "osd.h"
#include "../../Core/fileio.h"
#import <AVFoundation/AVFoundation.h>

void OSD::initialize_sound(int rate, int samples)
{
	sound_rate = rate;
	sound_samples = samples;
	sound_available = false;
	sound_started = false;
	sound_muted = false;
	sound_first_half = true;

	rec_sound_fio = NULL;
	rec_sound_bytes = 0;
	rec_sound_buffer_ptr = 0;
	now_record_sound = false;

	// Initialize ring buffer (4x sound_samples for headroom, stereo interleaved)
	ring_buffer_size = sound_samples * 2 * 4;  // stereo * 4x headroom
	sound_ring_buffer = (int16_t *)calloc(ring_buffer_size, sizeof(int16_t));
	ring_buffer_read_pos.store(0);
	ring_buffer_write_pos.store(0);

	// Initialize AVAudioEngine
	// Use __bridge_retained to store ObjC objects as void* (prevents ARC issues
	// since OSD is constructed from C++ context where ARC doesn't manage members)
	AVAudioEngine *engine = [[AVAudioEngine alloc] init];

	// Capture ring buffer state for the render block
	int16_t *ringBuf = sound_ring_buffer;
	int ringSize = ring_buffer_size;
	std::atomic<int> *readPos = &ring_buffer_read_pos;
	std::atomic<int> *writePos = &ring_buffer_write_pos;

	AVAudioFormat *format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
														    sampleRate:(double)rate
															  channels:2
														   interleaved:YES];

	AVAudioSourceNode *node = [[AVAudioSourceNode alloc] initWithFormat:format
			renderBlock:^OSStatus(BOOL *isSilence,
								 const AudioTimeStamp *timestamp,
								 AVAudioFrameCount frameCount,
								 AudioBufferList *outputData)
	{
		int rp = readPos->load(std::memory_order_acquire);
		int wp = writePos->load(std::memory_order_acquire);

		// Calculate available samples (stereo interleaved, so 2 int16_t per frame)
		int available = wp - rp;
		if(available < 0) {
			available += ringSize;
		}

		int framesToCopy = frameCount;
		int samplesNeeded = framesToCopy * 2;  // stereo

		AudioBuffer &buf = outputData->mBuffers[0];
		int16_t *outPtr = (int16_t *)buf.mData;

		if(available >= samplesNeeded) {
			// Enough data available
			*isSilence = NO;
			for(int i = 0; i < samplesNeeded; i++) {
				outPtr[i] = ringBuf[rp];
				rp++;
				if(rp >= ringSize) {
					rp = 0;
				}
			}
			readPos->store(rp, std::memory_order_release);
		} else {
			// Buffer underrun - output available data then silence
			*isSilence = (available == 0) ? YES : NO;
			for(int i = 0; i < available; i++) {
				outPtr[i] = ringBuf[rp];
				rp++;
				if(rp >= ringSize) {
					rp = 0;
				}
			}
			for(int i = available; i < samplesNeeded; i++) {
				outPtr[i] = 0;
			}
			readPos->store(rp, std::memory_order_release);
		}

		buf.mDataByteSize = framesToCopy * 2 * sizeof(int16_t);
		return noErr;
	}];

	// Speaker simulation EQ (4 bands)
	AVAudioUnitEQ *eq = [[AVAudioUnitEQ alloc] initWithNumberOfBands:4];

	// Band 0: HighPass 200Hz — small speaker low-end rolloff
	AVAudioUnitEQFilterParameters *band0 = eq.bands[0];
	band0.filterType = AVAudioUnitEQFilterTypeHighPass;
	band0.frequency = 200.0;
	band0.bandwidth = 1.0;
	band0.bypass = NO;

	// Band 1: Parametric 800Hz +3dB — cabinet resonance
	AVAudioUnitEQFilterParameters *band1 = eq.bands[1];
	band1.filterType = AVAudioUnitEQFilterTypeParametric;
	band1.frequency = 800.0;
	band1.bandwidth = 1.5;
	band1.gain = 3.0;
	band1.bypass = NO;

	// Band 2: Parametric 2kHz +5dB — cone resonance peak
	AVAudioUnitEQFilterParameters *band2 = eq.bands[2];
	band2.filterType = AVAudioUnitEQFilterTypeParametric;
	band2.frequency = 2000.0;
	band2.bandwidth = 1.0;
	band2.gain = 5.0;
	band2.bypass = NO;

	// Band 3: LowPass 8kHz — high-frequency rolloff
	AVAudioUnitEQFilterParameters *band3 = eq.bands[3];
	band3.filterType = AVAudioUnitEQFilterTypeLowPass;
	band3.frequency = 8000.0;
	band3.bandwidth = 1.0;
	band3.bypass = NO;

	eq.globalGain = -2.0;
	eq.bypass = !config.sound_speaker_simulation;

	AVAudioUnitTimePitch *chorus = [[AVAudioUnitTimePitch alloc] init];
	chorus.pitch = 7.0;     // +7 cents detune
	chorus.overlap = 32.0;

	// Wet path volume control — outputVolume controls chorus wet level
	AVAudioMixerNode *chorusWetGain = [[AVAudioMixerNode alloc] init];

	// Parallel mix point — bus 0: dry, bus 1: wet
	AVAudioMixerNode *chorusMixer = [[AVAudioMixerNode alloc] init];

	AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init];
	[reverb loadFactoryPreset:AVAudioUnitReverbPresetSmallRoom];
	reverb.wetDryMix = 25.0;
	reverb.bypass = !config.sound_reverb;

	[engine attachNode:node];
	[engine attachNode:eq];
	[engine attachNode:chorus];
	[engine attachNode:chorusWetGain];
	[engine attachNode:chorusMixer];
	[engine attachNode:reverb];
	[engine connect:node to:eq format:nil];

	// Parallel dry/wet paths via fan-out from EQ
	AVAudioConnectionPoint *dryPoint = [[AVAudioConnectionPoint alloc] initWithNode:chorusMixer bus:0];
	AVAudioConnectionPoint *wetPoint = [[AVAudioConnectionPoint alloc] initWithNode:chorus bus:0];
	[engine connect:eq toConnectionPoints:@[dryPoint, wetPoint] fromBus:0 format:nil];
	[engine connect:chorus to:chorusWetGain format:nil];
	[engine connect:chorusWetGain to:chorusMixer fromBus:0 toBus:1 format:nil];

	[engine connect:chorusMixer to:reverb format:nil];
	[engine connect:reverb to:engine.mainMixerNode format:nil];

	// Set wet gain AFTER connect (attach/connect may reset outputVolume)
	chorusWetGain.outputVolume = config.sound_chorus ? 0.35 : 0.0;

	NSError *error = nil;
	if([engine startAndReturnError:&error]) {
		sound_available = true;
		sound_started = true;
	} else {
		NSLog(@"AVAudioEngine start failed: %@", error);
		sound_available = false;
	}

	// Store as retained void* — we own the reference now
	audioEngine = (__bridge_retained void *)engine;
	sourceNode = (__bridge_retained void *)node;
	speakerEQNode = (__bridge_retained void *)eq;
	reverbNode = (__bridge_retained void *)reverb;
	chorusNode = (__bridge_retained void *)chorus;
	chorusWetGainNode = (__bridge_retained void *)chorusWetGain;
	chorusMixerNode = (__bridge_retained void *)chorusMixer;
}

void OSD::release_sound()
{
	stop_sound();

	if(sound_ring_buffer) {
		free(sound_ring_buffer);
		sound_ring_buffer = NULL;
	}

	if(audioEngine) {
		AVAudioEngine *engine = (__bridge AVAudioEngine *)audioEngine;
		if(reverbNode) {
			AVAudioUnitReverb *reverb = (__bridge AVAudioUnitReverb *)reverbNode;
			[engine detachNode:reverb];
		}
		if(chorusMixerNode) {
			AVAudioMixerNode *chorusMixer = (__bridge AVAudioMixerNode *)chorusMixerNode;
			[engine detachNode:chorusMixer];
		}
		if(chorusWetGainNode) {
			AVAudioMixerNode *chorusWetGain = (__bridge AVAudioMixerNode *)chorusWetGainNode;
			[engine detachNode:chorusWetGain];
		}
		if(chorusNode) {
			AVAudioUnitTimePitch *chorus = (__bridge AVAudioUnitTimePitch *)chorusNode;
			[engine detachNode:chorus];
		}
		if(speakerEQNode) {
			AVAudioUnitEQ *eq = (__bridge AVAudioUnitEQ *)speakerEQNode;
			[engine detachNode:eq];
		}
		if(sourceNode) {
			AVAudioSourceNode *node = (__bridge AVAudioSourceNode *)sourceNode;
			[engine detachNode:node];
		}
	}

	// Transfer ownership back to ARC for release
	if(reverbNode) {
		(void)(__bridge_transfer AVAudioUnitReverb *)reverbNode;
		reverbNode = NULL;
	}
	if(chorusMixerNode) {
		(void)(__bridge_transfer AVAudioMixerNode *)chorusMixerNode;
		chorusMixerNode = NULL;
	}
	if(chorusWetGainNode) {
		(void)(__bridge_transfer AVAudioMixerNode *)chorusWetGainNode;
		chorusWetGainNode = NULL;
	}
	if(chorusNode) {
		(void)(__bridge_transfer AVAudioUnitTimePitch *)chorusNode;
		chorusNode = NULL;
	}
	if(speakerEQNode) {
		(void)(__bridge_transfer AVAudioUnitEQ *)speakerEQNode;
		speakerEQNode = NULL;
	}
	if(sourceNode) {
		(void)(__bridge_transfer AVAudioSourceNode *)sourceNode;
		sourceNode = NULL;
	}
	if(audioEngine) {
		(void)(__bridge_transfer AVAudioEngine *)audioEngine;
		audioEngine = NULL;
	}
}

void OSD::update_sound(int* extra_frames)
{
	*extra_frames = 0;

	if(vm == NULL) {
		return;
	}

	// Create sound buffer from VM
	uint16_t* sound_buffer = vm->create_sound(extra_frames);
	if(sound_buffer == NULL) {
		return;
	}

	// Write to ring buffer (sound_samples frames, stereo interleaved)
	if(sound_available && !sound_muted) {
		int wp = ring_buffer_write_pos.load(std::memory_order_acquire);
		int samplesTotal = sound_samples * 2;  // stereo

		for(int i = 0; i < samplesTotal; i++) {
			sound_ring_buffer[wp] = (int16_t)sound_buffer[i];
			wp++;
			if(wp >= ring_buffer_size) {
				wp = 0;
			}
		}
		ring_buffer_write_pos.store(wp, std::memory_order_release);
	}

	// Record sound to file
	if(now_record_sound && rec_sound_fio != NULL) {
		rec_sound_fio->Fwrite(sound_buffer, sound_samples * sizeof(uint16_t) * 2, 1);
		rec_sound_bytes += sound_samples * sizeof(uint16_t) * 2;
	}

	sound_first_half = !sound_first_half;
}

void OSD::mute_sound()
{
	if(sound_available && audioEngine) {
		AVAudioEngine *engine = (__bridge AVAudioEngine *)audioEngine;
		[engine pause];
		sound_muted = true;
	}
}

void OSD::stop_sound()
{
	if(audioEngine) {
		AVAudioEngine *engine = (__bridge AVAudioEngine *)audioEngine;
		[engine stop];
	}
	sound_available = false;
	sound_started = false;
}

void OSD::start_record_sound()
{
	if(now_record_sound) {
		return;
	}
	create_date_file_path(sound_file_path, _MAX_PATH, _T("wav"));
	rec_sound_fio = new FILEIO();
	if(rec_sound_fio->Fopen(sound_file_path, FILEIO_WRITE_BINARY)) {
		// write dummy header (will be updated when recording stops)
		wav_header_t header;
		memset(&header, 0, sizeof(header));
		rec_sound_fio->Fwrite(&header, sizeof(header), 1);
		rec_sound_bytes = 0;
		now_record_sound = true;
	} else {
		delete rec_sound_fio;
		rec_sound_fio = NULL;
	}
}

void OSD::stop_record_sound()
{
	if(!now_record_sound) {
		return;
	}
	if(rec_sound_fio != NULL) {
		if(rec_sound_bytes > 0) {
			// update wav header
			wav_header_t header;
			memcpy(header.riff_chunk.id, "RIFF", 4);
			header.riff_chunk.size = rec_sound_bytes + sizeof(wav_header_t) - 8;
			memcpy(header.wave, "WAVE", 4);
			memcpy(header.fmt_chunk.id, "fmt ", 4);
			header.fmt_chunk.size = 16;
			header.format_id = 1;
			header.channels = 2;
			header.sample_rate = sound_rate;
			header.data_speed = sound_rate * 2 * sizeof(uint16_t);
			header.block_size = 2 * sizeof(uint16_t);
			header.sample_bits = 16;

			rec_sound_fio->Fseek(0, FILEIO_SEEK_SET);
			rec_sound_fio->Fwrite(&header, sizeof(header), 1);

			// write data chunk header
			wav_chunk_t data_chunk;
			memcpy(data_chunk.id, "data", 4);
			data_chunk.size = rec_sound_bytes;
			rec_sound_fio->Fwrite(&data_chunk, sizeof(data_chunk), 1);
		}
		rec_sound_fio->Fclose();
		delete rec_sound_fio;
		rec_sound_fio = NULL;
	}
	now_record_sound = false;
}

void OSD::restart_record_sound()
{
	// stub
}

void OSD::set_speaker_simulation(bool enabled)
{
	if(speakerEQNode) {
		AVAudioUnitEQ *eq = (__bridge AVAudioUnitEQ *)speakerEQNode;
		eq.bypass = !enabled;
	}
}

void OSD::set_reverb(bool enabled)
{
	if(reverbNode) {
		AVAudioUnitReverb *reverb = (__bridge AVAudioUnitReverb *)reverbNode;
		reverb.bypass = !enabled;
	}
}

void OSD::set_chorus(bool enabled)
{
	if(chorusWetGainNode) {
		AVAudioMixerNode *chorusWetGain = (__bridge AVAudioMixerNode *)chorusWetGainNode;
		chorusWetGain.outputVolume = enabled ? 0.35 : 0.0;
	}
}
