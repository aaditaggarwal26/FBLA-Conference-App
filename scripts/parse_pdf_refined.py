#!/usr/bin/env python3
"""
FBLA Event Schedule PDF Parser - Refined Version
Uses the actual PDF structure we observed
"""

import pdfplumber
import json
import re
from datetime import datetime

def parse_pdf_structured(pdf_path, output_path):
    """Parse PDF with better structure understanding"""
    all_events = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            text = page.extract_text()
            if not text:
                continue
            
            lines = [l.strip() for l in text.split('\n') if l.strip()]
            
            # Find event name - usually has "Final" or "Preliminary"
            event_name = None
            perform_location = None
            prep_location = None
            
            for i, line in enumerate(lines):
                # Event name line
                if 'Final' in line and ' - ' in line:
                    parts = line.split(' - ')
                    for part in parts:
                        if 'Final' in part or 'Preliminary' in part:
                            event_name = part.strip()
                            break
                
                # Location extraction
                if 'PerformLocation:' in line:
                    match = re.search(r'PerformLocation:(\d+)', line)
                    if match:
                        perform_location = match.group(1)
                
                if 'PrepLocation:' in line:
                    match = re.search(r'PrepLocation:(\d+)', line)
                    if match:
                        prep_location = match.group(1)
            
            if not event_name:
                continue
            
            # Now find participant entries
            # Pattern: School name, Participant names, Time
            # Example: "NorthCreekHighSchool VarunPatwardhan 9:00AM"
            for line in lines:
                # Look for lines with time stamps
                time_match = re.search(r'(\d{1,2}:\d{2}\s*[AP]M)', line)
                if not time_match:
                    continue
                
                time_str = time_match.group(1)
                
                # Extract text before time - these are participants
                before_time = line[:line.index(time_str)].strip()
                
                # Remove school names
                before_time = re.sub(r'NorthCreekHighSchool', '', before_time)
                before_time = re.sub(r'WestCentral', '', before_time)
                
                # Split into potential names (capitalized words)
                words = before_time.split()
                participants = []
                
                for word in words:
                    # Keep only properly capitalized names (CamelCase or proper names)
                    if word and len(word) > 1 and word[0].isupper():
                        # Skip common non-name words
                        if word.lower() not in ['event', 'when', 'saturday', 'schedule', 
                                                 'november', 'generated', 'page', 'of']:
                            participants.append(word)
                
                if participants:
                    all_events.append({
                        'eventName': event_name,
                        'performLocation': perform_location or '',
                        'prepLocation': prep_location or '',
                        'startTimeStr': time_str,
                        'participants': participants,
                        'pageNumber': page_num
                    })
    
    # Save to JSON
    with open(output_path, 'w') as f:
        json.dump(all_events, f, indent=2)
    
    print(f"✅ Parsed {len(all_events)} event entries from {len(pdf.pages)} pages")
    print(f"📁 Output saved to {output_path}")
    
    # Print statistics
    if all_events:
        print(f"\n📊 Event Statistics:")
        event_types = {}
        for event in all_events:
            name = event['eventName']
            event_types[name] = event_types.get(name, 0) + 1
        
        for event_type, count in sorted(event_types.items(), key=lambda x: x[1], reverse=True)[:10]:
            print(f"  {event_type}: {count} entries")
        
        print(f"\n📝 Sample event:")
        print(json.dumps(all_events[10] if len(all_events) > 10 else all_events[0], indent=2))

if __name__ == '__main__':
    pdf_path = '/Users/aaditaggarwal/Downloads/NCCC FINAL.pdf'
    output_path = '/Users/aaditaggarwal/Github/FBLA-Conference-App/lib/data/parsed_events.json'
    parse_pdf_structured(pdf_path, output_path)
