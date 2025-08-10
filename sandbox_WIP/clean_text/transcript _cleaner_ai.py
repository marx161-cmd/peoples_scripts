#!/usr/bin/env python3
import os
import sys
import time
import pyperclip
import re
from datetime import datetime

# Configuration
CONTEXT_LINES = 2  # Lines to keep before/after segment
COMPLETION_MARKER = "###CLEANED###"  # Text to detect cleaning completion

def process_transcript(input_file):
    # Read transcript
    with open(input_file, 'r') as f:
        lines = f.readlines()
    
    # Find segment markers (timestamps)
    segments = []
    current_segment = []
    segment_start = 0
    
    for i, line in enumerate(lines):
        if re.match(r'^\[\d{2}:\d{2}:\d{2}\]$', line.strip()):
            if current_segment:
                segments.append({
                    'start': segment_start,
                    'end': i-1,
                    'lines': current_segment.copy()
                })
                current_segment = []
            segment_start = i
        
        current_segment.append(line)
    
    # Add last segment
    if current_segment:
        segments.append({
            'start': segment_start,
            'end': len(lines)-1,
            'lines': current_segment.copy()
        })
    
    # Create output file
    output_file = f"{os.path.splitext(input_file)[0]}_CLEANED.txt"
    with open(output_file, 'w') as out_f:
        out_f.write(f"AI-Cleaned Transcript: {input_file}\n")
        out_f.write(f"Processing started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
    
    print(f"Processing {len(segments)} segments from {input_file}")
    print("------------------------------------------------")
    
    # Process each segment
    for idx, seg in enumerate(segments):
        # Create segment with context
        start_idx = max(0, seg['start'] - CONTEXT_LINES)
        end_idx = min(len(lines)-1, seg['end'] + CONTEXT_LINES)
        
        segment_content = []
        segment_content.append(f"\n\n─── SEGMENT {idx+1}/{len(segments)} ───")
        segment_content.extend(lines[start_idx:end_idx+1])
        segment_content.append(f"\n{COMPLETION_MARKER}")
        
        # Copy to clipboard
        pyperclip.copy('\n'.join(segment_content))
        
        # Display status
        os.system('clear')
        print(f"Processing: {input_file}")
        print(f"Segment {idx+1}/{len(segments)} copied to clipboard")
        print("------------------------------------------------")
        print("Instructions:")
        print("1. Paste into AI tool")
        print("2. Clean the content")
        print(f"3. Append '{COMPLETION_MARKER}' at end")
        print("4. Copy entire response to clipboard")
        print("------------------------------------------------")
        print("Waiting for cleaned content...")
        
        # Wait for cleaned content
        start_time = time.time()
        cleaned_content = ""
        
        while True:
            current_clip = pyperclip.paste()
            
            # Check for completion marker
            if COMPLETION_MARKER in current_clip:
                # Extract cleaned segment
                cleaned_segment = current_clip.split(COMPLETION_MARKER)[0].strip()
                
                # Remove context overhang
                cleaned_lines = cleaned_segment.split('\n')
                final_content = []
                in_segment = False
                
                for line in cleaned_lines:
                    if line.startswith('─── SEGMENT'):
                        in_segment = True
                        continue
                    if in_segment and re.match(r'^\[\d{2}:\d{2}:\d{2}\]$', line.strip()):
                        in_segment = True
                        final_content.append(line)
                    elif in_segment:
                        final_content.append(line)
                
                # Save to output
                with open(output_file, 'a') as out_f:
                    out_f.write('\n'.join(final_content))
                    out_f.write('\n\n')
                
                print("Segment processed successfully!")
                time.sleep(1)  # Pause for visibility
                break
            
            # Timeout check
            if time.time() - start_time > 300:  # 5-minute timeout
                print("\nTimeout waiting for cleaned content. Moving to next segment.")
                with open(output_file, 'a') as out_f:
                    out_f.write(f"\n\n⚠️ SEGMENT {idx+1} SKIPPED DUE TO TIMEOUT ⚠️\n\n")
                break
            
            time.sleep(2)  # Check clipboard every 2 seconds
    
    print("\nProcessing complete!")
    print(f"Cleaned transcript saved to: {output_file}")
    pyperclip.copy(f"Transcript processing complete: {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: ./ai-transcript-cleaner.py <transcript-file.txt>")
        sys.exit(1)
    
    process_transcript(sys.argv[1])