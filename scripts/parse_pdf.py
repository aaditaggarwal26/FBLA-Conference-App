#!/usr/bin/env python3
"""
FBLA Event Schedule PDF Parser
Parses the FBLA competition schedule PDF and extracts structured event data
"""

import pdfplumber
import json
import re
from datetime import datetime, time, timedelta

def parse_time(time_str):
    """Parse time string like '9:00AM' into time object"""
    time_str = time_str.strip().upper()
    match = re.match(r'(\d{1,2}):(\d{2})\s*(AM|PM)', time_str)
    if match:
        hour = int(match.group(1))
        minute = int(match.group(2))
        period = match.group(3)
        
        if period == 'PM' and hour != 12:
            hour += 12
        elif period == 'AM' and hour == 12:
            hour = 0
            
        return time(hour, minute)
    return None

def extract_events_from_page(page_text):
    """Extract event data from a single page"""
    events = []
    lines = page_text.strip().split('\n')
    
    if len(lines) < 5:
        return events
    
    # Parse header - event name is usually in first few lines
    event_name = None
    perform_location = None
    prep_location = None
    
    # Find the main event name (has "Final" or similar)
    for line in lines[:15]:
        if ('Final' in line or 'Preliminary' in line) and ' - ' in line:
            # Extract event name
            parts = line.split(' - ')
            for part in parts:
                if 'Final' in part or 'Preliminary' in part:
                    event_name = part.strip()
                    break
        
        # Extract locations
        if 'PerformLocation:' in line:
            match = re.search(r'PerformLocation:(\d+)', line)
            if match:
                perform_location = match.group(1)
        if 'PrepLocation:' in line:
            match = re.search(r'PrepLocation:(\d+)', line)
            if match:
                prep_location = match.group(1)
    
    if not event_name:
        return events
    
    # Find entries with participants and times
    # Look for lines with time patterns like "9:00AM"
    for i, line in enumerate(lines):
        time_match = re.search(r'(\d{1,2}:\d{2}\s*[AP]M)', line)
        if time_match and i > 0:
            time_str = time_match.group(1)
            
            # Extract participants - they're usually proper names (capitalized)
            # Look in current line and potentially previous line
            participant_text = line[:line.index(time_str)]
            
            # Also check previous line for more participants
            if i > 0:
                prev_line = lines[i-1]
                # If previous line doesn't have a time, it might be participants
                if not re.search(r'\d{1,2}:\d{2}\s*[AP]M', prev_line):
                    participant_text = prev_line + ' ' + participant_text
            
            # Extract participant names (capitalized words, not location names)
            words = participant_text.split()
            participants = []
            for word in words:
                # Filter out school names and common non-name words
                if (word.strip() and 
                    word[0].isupper() and 
                    'North' not in word and 
                    'Creek' not in word and
                    'West' not in word and
                    'Central' not in word and
                    'High' not in word and
                    'School' not in word and
                    len(word) > 1):
                    participants.append(word.strip())
            
            if participants:
                events.append({
                    'eventName': event_name,
                    'performLocation': perform_location,
                    'prepLocation': prep_location,
                    'startTimeStr': time_str,
                    'participants': participants
                })
    
    return events

def parse_pdf(pdf_path, output_path):
    """Parse the entire PDF and save as JSON"""
    all_events = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            text = page.extract_text()
            if text:
                events = extract_events_from_page(text)
                for event in events:
                    event['pageNumber'] = page_num
                all_events.extend(events)
    
    # Save to JSON
    with open(output_path, 'w') as f:
        json.dump(all_events, f, indent=2)
    
    print(f"Parsed {len(all_events)} event entries from {len(pdf.pages)} pages")
    print(f"Output saved to {output_path}")
    
    # Print sample
    if all_events:
        print("\nSample event:")
        print(json.dumps(all_events[0], indent=2))

if __name__ == '__main__':
    pdf_path = '/Users/aaditaggarwal/Downloads/NCCC FINAL.pdf'
    output_path = '/Users/aaditaggarwal/Github/FBLA-Conference-App/lib/data/parsed_events.json'
    parse_pdf(pdf_path, output_path)
