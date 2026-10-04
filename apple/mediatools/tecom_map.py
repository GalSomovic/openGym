"""US Marine Corps TECOM (Force Fitness Division) exercise library on DVIDS: title -> openGym ids.
Curated by hand; each clip is still checked by eye after cutting (titles are sometimes wrong)."""
TECOM_TO_OPENGYM = {
    # bodyweight
    "Pushups": ["0662"], "Abdominal Crunch": ["0274"], "Bear Crawl": ["3360"], "Body Weight Squat": ["gf-squat"],
    "Stationary Squat": ["gf-squat"], "Burpee": ["1160"], "Eight Count Body Builders": ["1160"], "Clap Pushups": ["1273"],
    "Plyo Push Up": ["1306"], "Dead Hang Pullup": ["0652", "gf-dead-hang"], "Flutter kicks": ["0459"],
    "Hanging Knee Raises": ["0472"], "Hanging Leg Raises": ["0475"], "Hanging Oblique Knee Raises": ["1761"],
    "High Knees": ["gf-high-knees"], "Inchworm": ["1471", "3698"], "Knee to Elbow Push-Up": ["0778"],
    "Leg Lowers": ["gf-lying-leg-raise"], "Monster Walk": ["0628"], "Mountain Climbers": ["0630"], "Plank": ["gf-plank"],
    "Prisoner Squat Jump": ["0514"], "Prone Superman": ["gf-superman"], "Reverse Lunge": ["gf-reverse-lunge"],
    "Stationary Reverse Lunge": ["gf-reverse-lunge"], "Stationary Forward Lunge": ["3470"], "Walking Lunge": ["1460"],
    "Walking Lunge with Twist": ["1688"], "Russian Twist": ["0687"], "Side Plank": ["gf-side-plank"],
    "Side Straddle Hops": ["gf-jumping-jack", "3224"], "Star Jump": ["3223"], "Speed Skaters": ["3361"],
    "Toe Touches": ["3212"], "Oblique Heel Touch": ["0006"], "V Ups": ["gf-v-up", "0507"], "Windshield Wipers": ["0500"],
    "Explosive Calf Raise": ["1373"],
    # stretches
    "Butterfly Stretch": ["1494"], "Tricep Stretch": ["0817"], "Chest Stretch": ["1271"], "Neck Stretch": ["1403"],
    "Upper Back Stretch": ["1365"], "Side Bend Stretch": ["0794"],
    # dumbbell
    "Dumbbell Bench Press": ["0289"], "Dumbbell Incline Bench Press": ["0314"], "Dumbbell Bent Over Rows": ["0293"],
    "Dumbbell Curl": ["0294"], "Dumbbell Hammer Curl": ["0313"], "Dumbbell Kickback": ["0333"], "Dumbbell Lunge": ["0336"],
    "Dumbbell Romanian Deadlift": ["1459"], "Dumbbell Shoulder Press": ["0426"], "Dumbbel Arnold Press": ["2137"],
    "Dumbbell Squat": ["0413"], "Dumbbell Split Squat": ["0410"], "Dumbbell Single Leg Deadlift": ["1757"],
    "Dumbbell Tricep Extensions": ["0430"],
    # barbell
    "Barbell Back Squat": ["0043"], "Barbell Bench Press": ["0025"], "Barbell Bent Over Row": ["0027"],
    "Barbell Deadlift": ["0032"], "Barbell Front Squat": ["0042"], "Barbell Good Monrning": ["0044"],
    "Barbell Incline Press": ["0047"], "Barbell Overhead Squat": ["0069"], "Barbell Romanian Deadlift": ["0085"],
    "Barbell Split Squat": ["2810"], "Barbbell Bicep Curl": ["0031"], "Barbell Reverse Lunge": ["0078"],
    "Barbell Forward Lunge": ["0054"], "Barbell Lateral Lunge": ["1410"], "Close Grip Bench Press": ["0030"],
    "Power Clean": ["0648"], "EZ Bar Curl": ["0447"], "Hexbar Deadlift": ["0811"],
    # kettlebell, bands, medicine ball, suspension
    "Kettlebell Swing": ["0549"], "Kettlebell Goblet Squat": ["0534"], "Kettlebell Windmill": ["0554"],
    "Kettlebell Row - Single Arm": ["0541"], "Kettlebell Renegade Row": ["0521"], "Farmer Carry": ["2133"],
    "Kettlebell Farmer Carry": ["2133"], "Tire Flip": ["2459"], "Band Squat": ["1004"], "Band Shoulder Press": ["0997"],
    "Band Front Raise": ["0978"], "Med Ball Slam": ["1354"], "Med Ball Russian Twist": ["0846"],
    "Smith Machine Inverted Row": ["0499"], "TRX Inverted Row": ["0498"], "TRX Push Up": ["0806"],
    "TRX Split Squat": ["0809"], "TRX Low Row": ["0808"],
    # second pass over the rest of the library
    "Alternating Plyo Pushups": ["1306"], "Plyo Push ups (Hands Out)": ["1306"],
    "Barbell Bulgarian Split Squat": ["0099"], "Dumbbell Bulgarian Split Squat": ["0410", "gf-bulgarian-split-squat"],
    "Kettlebell Bulgarian Split Squat": ["gf-bulgarian-split-squat"], "Dumbbell Single Leg Squat": ["0411"],
    "Kettlebell Pistol Box Squat": ["0544"], "PVC Overhead Squat": ["0069"], "Double Kettlebell Push Press": ["0528"],
    "Kettlebell Double Windmill": ["0530"], "Kettlebell Military Press": ["0553"],
    "Hip Abduction": ["0710"], "Kettlebell Clean": ["0535"], "Lat Stretch on Bar": ["1346"], "Knee Circles": ["0257"],
    "Barbell Standing Press": ["1457"], "Military Press": ["1457"],
}

# Other public-domain DVIDS demos outside the TECOM library: video id -> (title, openGym ids). These have
# intros and talking, so each one is cut at a hand-picked window (start, length) checked on a contact sheet.
OTHER_VIDEOS = {
    "video:590723": ("Follow Me Fitness Normal Base Push-Up", ["0662"], (27.2, 4.4)),
    "video:592104": ("Follow me Fitness Close Base Push-Up", ["0259"], (27.9, 3.9)),
    "video:591612": ("Follow me Fitness Wide Base Push-Up", ["1311"], (21.4, 6.9)),
    "video:590930": ("Follow Me Fitness Incline Base Push-Up", ["0493"], (23.3, 6.4)),
    "video:590985": ("Follow me Fitness Decline Base Push-Up", ["0279"], (24.2, 5.0)),
}
