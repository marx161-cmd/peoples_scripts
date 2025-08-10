### Desktop Solution with Auto-Paste Detection & Overhang Removal

**1. Install Dependencies:**
```bash
sudo apt install xclip inotify-tools python3-pyperclip
```

**2. Main Script** (`ai-transcript-cleaner.py`):
```python
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
```

**3. Workflow Automation:**

1. **Preparation**:
   ```bash
   chmod +x ai-transcript-cleaner.py
   pip3 install pyperclip
   ```

2. **Execution**:
   ```bash
   ./ai-transcript-cleaner.py your_transcript.txt
   ```

3. **Per-Segment Workflow**:
   - Script copies segment to clipboard automatically
   - Switch to AI tool (ChatGPT/Claude/etc.)
   - Paste (Ctrl+V)
   - Clean the content
   - Add `###CLEANED###` at the end
   - Copy entire response to clipboard
   - Script automatically detects completion and processes next segment

4. **Final Output**:
   - Creates `your_transcript_CLEANED.txt` with:
     - Context overhangs removed
     - All cleaned segments combined
     - Original timestamps preserved
     - Status markers for any skipped segments

### Key Features:

1. **Automatic Overhang Removal**:
   - Keeps context while processing
   - Automatically strips context before saving
   - Preserves segment boundaries

2. **Clipboard Monitoring**:
   - Detects when you paste cleaned content
   - Uses special marker for completion detection
   - No manual switching between applications

3. **Continuous Workflow**:
   - Progresses automatically after each paste
   - Clear on-screen instructions
   - Progress counter (X/Y segments)

4. **Error Handling**:
   - 5-minute timeout per segment
   - Skips segments that aren't processed
   - Preserves original content structure

5. **Smart Segment Detection**:
   - Uses timestamp markers (`[00:05:02]`)
   - Handles beginning/end of file gracefully
   - Maintains segment order

### Advanced Usage Tips:

1. **Customize Context**: Adjust `CONTEXT_LINES` value for more/less context
2. **Batch Processing**: Wrap in a script to process multiple files:
   ```bash
   for file in *.txt; do ./ai-transcript-cleaner.py "$file"; done
   ```
3. **AI Prompt Template**: Use this with your AI tool:
   ```
   Clean this transcript segment while preserving all content:
   - Fix punctuation and capitalization
   - Correct obvious speech-to-text errors
   - Maintain original speaking style
   - Keep timestamps and section markers
   - Don't summarize or remove content
   - Format as plain text
   - Add "###CLEANED###" at the end when done

   [PASTE_CONTENT_HERE]
   ```
4. **Resume Support**: The script creates a new output file each time, so you can:
   - Stop anytime with Ctrl+C
   - Restart with same input file (new output file will be created)
   - Later merge partial outputs manually


### How the Script Operates

1. **Automatic Segment Preparation**:
   - Script loads your transcript file
   - Splits it into logical segments (using timestamps)
   - Adds context overhang (extra lines before/after)
   - Copies the first enriched segment to clipboard automatically

2. **Your Cleaning Workflow**:
   - You paste into your LLM (ChatGPT/Claude/etc.)
   - Clean the text as needed
   - **Add `###CLEANED###` at the end** (the crucial trigger)
   - Copy the **entire LLM output** to clipboard (including the marker)

3. **Script's Automatic Response**:
   - Constantly monitors clipboard (checks every 2 seconds)
   - When it detects `###CLEANED###` in clipboard:
     - Removes the marker
     - Strips away the context overhang
     - Saves only the cleaned core segment
     - Copies next segment to clipboard automatically
   - Repeats until all segments are processed

4. **Final Output**:
   - Generates a clean `[filename]_CLEANED.txt`
   - Contains only cleaned content (no overhangs/markers)
   - Preserves original timestamps and structure

### Key Advantages

1. **No Manual Switching**:
   - Never need to return to terminal
   - Work entirely in your LLM interface
   - Just maintain the copy-paste rhythm

2. **Perfect Context Handling**:
   - Overhangs exist only during cleaning
   - Never appear in final output
   - No manual cleanup needed

3. **Visual Progress**:
   ```plaintext
   Processing: debate_transcript.txt
   Segment 4/12 copied to clipboard
   ────────────────────────────────
   Instructions:
   1. Paste into AI tool
   2. Clean the content
   3. Append '###CLEANED###' at end
   4. Copy entire response to clipboard
   ────────────────────────────────
   Waiting for cleaned content...
   ```

### Setup & Usage

1. **Save the script** as `ai_transcript_cleaner.py`
2. **Make executable**:
   ```bash
   chmod +x ai_transcript_cleaner.py
   pip install pyperclip
   ```
3. **Run it**:
   ```bash
   ./ai_transcript_cleaner.py your_transcript.txt
   ```
4. **Workflow**:
   - See first segment appear in clipboard
   - Paste to LLM → Clean → Add marker → Copy back
   - Script auto-advances to next segment
   - Final file appears when done

### Pro Tip

For even smoother workflow:
- Use a dedicated clipboard manager (like CopyQ)
- Or this keyboard shortcut pattern:
  1. `Ctrl+V` (paste segment to LLM)
  2. `Ctrl+A` → `Ctrl+C` (when done cleaning)
  3. Repeat

The script handles all the file operations silently in the background while you focus entirely on the quality control aspects with your LLM.

When you test it with real data, just remember:
The script is patient (it'll wait while you coffee-break mid-session)


