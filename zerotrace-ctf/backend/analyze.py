import asyncio
import json
from pathlib import Path

# Paths to seed files
SEEDS_DIR = Path("config/seeds")
SEED_FILES = [
    "foundations-challenge-todo.seed.json",
    "linux-challenges-11-22.seed.json",
    "networking-challenges-23-32.seed.json"
]

def load_challenge_lab_service():
    from app.services.challenge_lab_service import ChallengeLabService
    return ChallengeLabService()

async def analyze_boundaries():
    print("ZeroTrace CTF - Boundaries Analysis Report\n" + "="*50)
    
    lab_service = load_challenge_lab_service()
    
    total_challenges = 0
    challenges_without_flag = 0
    challenges_needing_lab_but_missing = 0
    
    for seed_file in SEED_FILES:
        with open(SEEDS_DIR / seed_file) as f:
            data = json.load(f)
            
        track_name = data["track"]["name"]
        print(f"\nAnalyzing Track: {track_name}")
        print("-" * 50)
        
        for module in data["modules"]:
            for item in module["challenges"]:
                total_challenges += 1
                slug = item["slug"]
                title = item["title"]
                flag = item.get("flag")
                
                boundaries = []
                
                # Boundary 1: Flag is redacted
                if flag == "REDACTED_USE_PRIVATE_FLAGS_FILE":
                    boundaries.append("Flag relies on REDACTED_USE_PRIVATE_FLAGS_FILE and is missing.")
                    challenges_without_flag += 1
                    
                # Boundary 2: Lab is missing
                # A lot of these require labs or attachments. The backend does not support attachments.
                # Linux challenges definitely need a lab.
                has_lab = lab_service.has_lab(slug)
                needs_lab = track_name in ["Linux"] or "lab" in item["description"].lower()
                
                if needs_lab and not has_lab:
                    boundaries.append("Challenge requires a Terminal Lab, but none is implemented in ChallengeLabService.")
                    challenges_needing_lab_but_missing += 1
                elif has_lab:
                    boundaries.append("Lab successfully configured.")
                    
                # Boundary 3: Attachments missing
                needs_attachment = track_name in ["Networking"] or "pcap" in item["description"].lower() or "attachment" in item["description"].lower()
                if needs_attachment:
                    boundaries.append("Challenge requires a file attachment (PCAP, etc.), but the backend Schema/DB does not support attachments.")
                
                # Output challenge status
                if len(boundaries) > 0 and not (len(boundaries) == 1 and boundaries[0] == "Lab successfully configured."):
                    print(f"[!] {title} ({slug})")
                    for b in boundaries:
                        if b != "Lab successfully configured.":
                            print(f"    - {b}")
                else:
                    print(f"[OK] {title} ({slug})")
                    
    print("\nSummary Validation:")
    print(f"Total Challenges: {total_challenges}")
    print(f"Missing Flags: {challenges_without_flag}")
    print(f"Missing Labs (where expected): {challenges_needing_lab_but_missing}")
    
if __name__ == "__main__":
    asyncio.run(analyze_boundaries())
