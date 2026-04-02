import Foundation

/// Static exercise catalog. IDs are stable UUIDs used across templates, seeding, and references.
enum ExerciseLibrary {

    // MARK: - Stable Exercise IDs

    // Anchor – Upper
    static let benchPressID       = UUID(uuidString: "E0000001-0000-0000-0000-000000000000")!
    static let ohpID              = UUID(uuidString: "E0000002-0000-0000-0000-000000000000")!

    // Anchor – Lower
    static let backSquatID        = UUID(uuidString: "E0000003-0000-0000-0000-000000000000")!
    static let romanianDLID       = UUID(uuidString: "E0000004-0000-0000-0000-000000000000")!

    // Secondary – Upper
    static let barbellRowID       = UUID(uuidString: "E0000005-0000-0000-0000-000000000000")!
    static let inclineDBPressID   = UUID(uuidString: "E0000006-0000-0000-0000-000000000000")!
    static let pullUpsID          = UUID(uuidString: "E0000007-0000-0000-0000-000000000000")!
    static let dipsID             = UUID(uuidString: "E0000008-0000-0000-0000-000000000000")!
    static let cableRowID         = UUID(uuidString: "E0000009-0000-0000-0000-000000000000")!
    static let dbShoulderPressID  = UUID(uuidString: "E0000010-0000-0000-0000-000000000000")!

    // Secondary – Lower
    static let legPressID         = UUID(uuidString: "E0000011-0000-0000-0000-000000000000")!
    static let bulgarianSSID      = UUID(uuidString: "E0000012-0000-0000-0000-000000000000")!
    static let legCurlID          = UUID(uuidString: "E0000013-0000-0000-0000-000000000000")!
    static let hackSquatID        = UUID(uuidString: "E0000014-0000-0000-0000-000000000000")!
    static let gobletSquatID      = UUID(uuidString: "E0000015-0000-0000-0000-000000000000")!

    // Accessory – Upper
    static let bicepCurlID        = UUID(uuidString: "E0000016-0000-0000-0000-000000000000")!
    static let lateralRaiseID     = UUID(uuidString: "E0000017-0000-0000-0000-000000000000")!
    static let tricepPushdownID   = UUID(uuidString: "E0000018-0000-0000-0000-000000000000")!
    static let facePullID         = UUID(uuidString: "E0000019-0000-0000-0000-000000000000")!
    static let cableChestFlyeID   = UUID(uuidString: "E0000020-0000-0000-0000-000000000000")!
    static let hammerCurlID       = UUID(uuidString: "E0000021-0000-0000-0000-000000000000")!
    static let ohTricepExtID      = UUID(uuidString: "E0000022-0000-0000-0000-000000000000")!

    // Accessory – Lower
    static let legExtensionID     = UUID(uuidString: "E0000023-0000-0000-0000-000000000000")!
    static let calfRaiseID        = UUID(uuidString: "E0000024-0000-0000-0000-000000000000")!
    static let hipThrustID        = UUID(uuidString: "E0000025-0000-0000-0000-000000000000")!
    static let walkingLungesID    = UUID(uuidString: "E0000026-0000-0000-0000-000000000000")!

    // Core / Abs
    static let cableCrunchID      = UUID(uuidString: "E0000027-0000-0000-0000-000000000000")!
    static let hangingLegRaiseID  = UUID(uuidString: "E0000028-0000-0000-0000-000000000000")!
    static let abWheelRolloutID   = UUID(uuidString: "E0000029-0000-0000-0000-000000000000")!
    static let plankID            = UUID(uuidString: "E0000030-0000-0000-0000-000000000000")!
    static let russianTwistID     = UUID(uuidString: "E0000031-0000-0000-0000-000000000000")!
    static let declineSitUpID     = UUID(uuidString: "E0000032-0000-0000-0000-000000000000")!

    // New Compound / Program-Specific
    static let conventionalDLID   = UUID(uuidString: "E0000033-0000-0000-0000-000000000000")!
    static let closeGripBenchID   = UUID(uuidString: "E0000034-0000-0000-0000-000000000000")!
    static let arnoldPressID      = UUID(uuidString: "E0000035-0000-0000-0000-000000000000")!
    static let dbPulloverID       = UUID(uuidString: "E0000036-0000-0000-0000-000000000000")!
    static let tBarRowID          = UUID(uuidString: "E0000037-0000-0000-0000-000000000000")!
    static let preacherCurlID     = UUID(uuidString: "E0000038-0000-0000-0000-000000000000")!

    // User-requested additions
    static let seatedOHPID             = UUID(uuidString: "E0000039-0000-0000-0000-000000000000")!
    static let bicycleCrunchID         = UUID(uuidString: "E0000040-0000-0000-0000-000000000000")!
    static let reverseCrunchID         = UUID(uuidString: "E0000041-0000-0000-0000-000000000000")!
    static let benchDipsID             = UUID(uuidString: "E0000042-0000-0000-0000-000000000000")!

    // Researched additions
    static let latPulldownID           = UUID(uuidString: "E0000043-0000-0000-0000-000000000000")!
    static let closeGripLatPulldownID  = UUID(uuidString: "E0000044-0000-0000-0000-000000000000")!
    static let singleArmDBRowID        = UUID(uuidString: "E0000045-0000-0000-0000-000000000000")!
    static let chestSupportedRowID     = UUID(uuidString: "E0000046-0000-0000-0000-000000000000")!
    static let seatedCableFlyLowID     = UUID(uuidString: "E0000047-0000-0000-0000-000000000000")!
    static let skullCrushersID         = UUID(uuidString: "E0000048-0000-0000-0000-000000000000")!
    static let concentrationCurlID     = UUID(uuidString: "E0000049-0000-0000-0000-000000000000")!
    static let inclineDBCurlID         = UUID(uuidString: "E0000050-0000-0000-0000-000000000000")!
    static let sumoDeadliftID          = UUID(uuidString: "E0000051-0000-0000-0000-000000000000")!
    static let frontSquatID            = UUID(uuidString: "E0000052-0000-0000-0000-000000000000")!
    static let goodMorningsID          = UUID(uuidString: "E0000053-0000-0000-0000-000000000000")!
    static let nordicHamstringCurlID   = UUID(uuidString: "E0000054-0000-0000-0000-000000000000")!
    static let cableGluteKickbackID    = UUID(uuidString: "E0000055-0000-0000-0000-000000000000")!
    static let dbShrugsID              = UUID(uuidString: "E0000056-0000-0000-0000-000000000000")!

    // MARK: - All Exercises

    static func allExercises() -> [Exercise] {
        return [
            // ── Anchor – Upper ──────────────────────────────────────────────

            Exercise(
                id: benchPressID,
                name: "Barbell Bench Press",
                primaryMuscles: ["Chest"],
                secondaryMuscles: ["Triceps", "Front Delt"],
                tier: .anchor,
                bodyRegion: "upper",
                movementDescription: "Horizontal push from a flat bench using a barbell. The primary strength driver for chest development.",
                formCues: "Retract shoulder blades and keep them pinned throughout. Bar touches mid-chest, not your throat. Drive feet into the floor for leg drive. Control the descent — don't bounce off your chest.",
                isBodyweight: false,
                suggestedStartWeightLbs: 95,
                alternativeIDs: [inclineDBPressID, dipsID, cableChestFlyeID]
            ),

            Exercise(
                id: ohpID,
                name: "Overhead Press",
                primaryMuscles: ["Front Delt"],
                secondaryMuscles: ["Triceps", "Upper Chest", "Lateral Delt"],
                tier: .anchor,
                bodyRegion: "upper",
                movementDescription: "Vertical push with a barbell from the front rack position to full lockout overhead.",
                formCues: "Brace your core hard — your lower back should not hyperextend. Bar path is straight up, slightly back at the top. Lock out fully at the top. Elbows slightly forward of the bar, not flared out.",
                isBodyweight: false,
                suggestedStartWeightLbs: 65,
                alternativeIDs: [dbShoulderPressID]
            ),

            // ── Anchor – Lower ──────────────────────────────────────────────

            Exercise(
                id: backSquatID,
                name: "Barbell Back Squat",
                primaryMuscles: ["Quads"],
                secondaryMuscles: ["Glutes", "Hamstrings", "Core"],
                tier: .anchor,
                bodyRegion: "lower",
                movementDescription: "Barbell on upper back, descend until hips are below parallel, drive back up. The cornerstone of lower body strength.",
                formCues: "Bar on upper traps, not your neck. Brace core before unracking. Knees track over toes — push them out. Hit depth: hip crease below knee. Drive through the whole foot on the way up.",
                isBodyweight: false,
                suggestedStartWeightLbs: 95,
                alternativeIDs: [hackSquatID, gobletSquatID, legPressID]
            ),

            Exercise(
                id: romanianDLID,
                name: "Romanian Deadlift",
                primaryMuscles: ["Hamstrings"],
                secondaryMuscles: ["Glutes", "Lower Back"],
                tier: .anchor,
                bodyRegion: "lower",
                movementDescription: "Hip hinge with a barbell, lowering until you feel a strong hamstring stretch, then driving hips forward to stand.",
                formCues: "Soft bend in the knees throughout. Push your hips back, not straight down. Bar stays close to your legs — almost drags. Maintain a neutral spine, don't round your lower back. Feel the stretch before reversing.",
                isBodyweight: false,
                suggestedStartWeightLbs: 95,
                alternativeIDs: [legCurlID, hipThrustID]
            ),

            // ── Secondary – Upper ───────────────────────────────────────────

            Exercise(
                id: barbellRowID,
                name: "Barbell Row",
                primaryMuscles: ["Upper Back"],
                secondaryMuscles: ["Biceps", "Rear Delt", "Lower Back"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Hinge at the hips, pull a barbell into your lower rib cage. A cornerstone horizontal pull for back thickness.",
                formCues: "Hinge until torso is roughly 45°. Pull to the belly button, not your chest. Squeeze shoulder blades together at the top. Don't use momentum — control the eccentric.",
                isBodyweight: false,
                suggestedStartWeightLbs: 75,
                alternativeIDs: [cableRowID, pullUpsID]
            ),

            Exercise(
                id: inclineDBPressID,
                name: "Incline Dumbbell Press",
                primaryMuscles: ["Upper Chest"],
                secondaryMuscles: ["Front Delt", "Triceps"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Dumbbell press on a bench set to 30–45°. Emphasizes the upper portion of the chest.",
                formCues: "Set the bench at 30–45°, not too steep. Neutral wrist grip. Lower dumbbells to the sides of your chest. Press to a point slightly inside your shoulders at the top.",
                isBodyweight: false,
                suggestedStartWeightLbs: 40,
                alternativeIDs: [benchPressID, cableChestFlyeID]
            ),

            Exercise(
                id: pullUpsID,
                name: "Pull-Ups",
                primaryMuscles: ["Upper Back", "Lats"],
                secondaryMuscles: ["Biceps", "Rear Delt"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Bodyweight vertical pull from a dead hang to chin above bar. One of the best lat and back builders available.",
                formCues: "Dead hang at the bottom — full extension. Pull elbows down and back, not just bend your arms. Chin clears the bar at the top. Control the descent back to a dead hang.",
                isBodyweight: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [barbellRowID, cableRowID]
            ),

            Exercise(
                id: dipsID,
                name: "Dips",
                primaryMuscles: ["Triceps"],
                secondaryMuscles: ["Chest", "Front Delt"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Bodyweight dip on parallel bars, pressing back to full lockout. Excellent for tricep mass and lower chest.",
                formCues: "Lean forward slightly for more chest involvement, stay upright for more triceps. Lower until upper arms are parallel to the floor. Full lockout at the top. Don't swing.",
                isBodyweight: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [benchPressID, tricepPushdownID]
            ),

            Exercise(
                id: cableRowID,
                name: "Cable Row",
                primaryMuscles: ["Upper Back"],
                secondaryMuscles: ["Biceps", "Rear Delt"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Seated cable row with a neutral or pronated grip. Allows consistent tension throughout the range of motion.",
                formCues: "Sit tall — don't lean back to cheat the weight. Pull the handle into your lower chest/stomach. Squeeze shoulder blades together at the end range. Slow, controlled return.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [barbellRowID, pullUpsID]
            ),

            Exercise(
                id: dbShoulderPressID,
                name: "Dumbbell Shoulder Press",
                primaryMuscles: ["Front Delt"],
                secondaryMuscles: ["Lateral Delt", "Triceps"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Seated or standing dumbbell press overhead. Allows a more natural wrist path than a barbell.",
                formCues: "Start with dumbbells at ear height. Press straight up and slightly together at the top. Don't lock elbows aggressively — keep tension on the deltoid. Control the descent.",
                isBodyweight: false,
                suggestedStartWeightLbs: 30,
                alternativeIDs: [ohpID]
            ),

            // ── Secondary – Lower ───────────────────────────────────────────

            Exercise(
                id: legPressID,
                name: "Leg Press",
                primaryMuscles: ["Quads"],
                secondaryMuscles: ["Glutes", "Hamstrings"],
                tier: .secondary,
                bodyRegion: "lower",
                movementDescription: "Machine-based leg press. High loading capacity with lower spinal load than squats.",
                formCues: "Feet shoulder-width, mid-height on the platform. Lower until knees reach 90°. Don't lock knees at the top — keep slight bend. Never let knees cave inward.",
                isBodyweight: false,
                suggestedStartWeightLbs: 90,
                alternativeIDs: [backSquatID, hackSquatID, bulgarianSSID]
            ),

            Exercise(
                id: bulgarianSSID,
                name: "Bulgarian Split Squat",
                primaryMuscles: ["Quads"],
                secondaryMuscles: ["Glutes", "Hamstrings"],
                tier: .secondary,
                bodyRegion: "lower",
                movementDescription: "Single-leg squat with rear foot elevated on a bench. High quad and glute demand with a significant balance component.",
                formCues: "Rear foot on bench, laces down or heel up. Front foot far enough forward that your knee doesn't travel past your toes. Descend straight down. Keep torso upright.",
                isBodyweight: false,
                suggestedStartWeightLbs: 30,
                alternativeIDs: [legPressID, walkingLungesID]
            ),

            Exercise(
                id: legCurlID,
                name: "Leg Curl",
                primaryMuscles: ["Hamstrings"],
                secondaryMuscles: ["Calves"],
                tier: .secondary,
                bodyRegion: "lower",
                movementDescription: "Machine leg curl, lying or seated. Isolates the hamstrings through knee flexion.",
                formCues: "Don't let hips rise off the pad when curling. Full extension at the bottom. Squeeze hard at full flexion. Slow eccentric — lower with control.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [romanianDLID, hipThrustID]
            ),

            Exercise(
                id: hackSquatID,
                name: "Hack Squat",
                primaryMuscles: ["Quads"],
                secondaryMuscles: ["Glutes"],
                tier: .secondary,
                bodyRegion: "lower",
                movementDescription: "Machine hack squat. Allows a very upright torso for maximum quad emphasis.",
                formCues: "Feet low on the platform for more quad focus. Full depth — thighs parallel or below. Keep lower back flat against the pad. Drive through your whole foot.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [backSquatID, legPressID]
            ),

            Exercise(
                id: gobletSquatID,
                name: "Goblet Squat",
                primaryMuscles: ["Quads"],
                secondaryMuscles: ["Glutes", "Core"],
                tier: .secondary,
                bodyRegion: "lower",
                movementDescription: "Front-loaded squat holding a dumbbell or kettlebell at the chest. Excellent for squat mechanics and quad development.",
                formCues: "Hold weight at sternum with both hands. Elbows inside knees at the bottom. Keep chest tall throughout. Sit into the squat rather than hinging.",
                isBodyweight: false,
                suggestedStartWeightLbs: 35,
                alternativeIDs: [backSquatID, legPressID]
            ),

            // ── Accessory – Upper ───────────────────────────────────────────

            Exercise(
                id: bicepCurlID,
                name: "Barbell Bicep Curl",
                primaryMuscles: ["Biceps"],
                secondaryMuscles: ["Brachialis"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Standing barbell curl, targeting the biceps through elbow flexion.",
                formCues: "Keep elbows pinned at your sides. Don't swing the bar — control the movement. Supinate (rotate) the wrist at the top. Slow 2-second descent.",
                isBodyweight: false,
                suggestedStartWeightLbs: 35,
                alternativeIDs: [hammerCurlID]
            ),

            Exercise(
                id: lateralRaiseID,
                name: "Lateral Raises",
                primaryMuscles: ["Lateral Delt"],
                secondaryMuscles: ["Front Delt", "Supraspinatus"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Dumbbell lateral raise to build shoulder width and the medial deltoid.",
                formCues: "Slight forward lean and a slight bend in the elbow. Lead with your elbows, not your hands. Stop at shoulder height — going higher shifts load to traps. Don't swing.",
                isBodyweight: false,
                suggestedStartWeightLbs: 15,
                alternativeIDs: [facePullID]
            ),

            Exercise(
                id: tricepPushdownID,
                name: "Tricep Pushdown",
                primaryMuscles: ["Triceps"],
                secondaryMuscles: [],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Cable pushdown using a straight bar or rope attachment. Targets all three heads of the triceps.",
                formCues: "Elbows stay at your sides — if they rise, reduce the weight. Full extension at the bottom. Control the return — let the weight pull your hands up slowly. Rope: spread apart at the bottom for lateral head emphasis.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [ohTricepExtID, dipsID]
            ),

            Exercise(
                id: facePullID,
                name: "Face Pulls",
                primaryMuscles: ["Rear Delt"],
                secondaryMuscles: ["Rotator Cuff", "Traps"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Cable face pull to the forehead or nose. Excellent for shoulder health and rear delt/rotator cuff development.",
                formCues: "Set cable high. Pull to face level — not your chest. Elbows high and wide at the end. Externally rotate at the end (hands go back). Use light weight and high reps.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [lateralRaiseID]
            ),

            Exercise(
                id: cableChestFlyeID,
                name: "Cable Chest Flye",
                primaryMuscles: ["Chest"],
                secondaryMuscles: ["Front Delt"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Cable fly from a high or low pulley, providing constant tension through the entire range of motion.",
                formCues: "Slight bend in the elbows, locked throughout. Squeeze chest at the point of full contraction. Don't let arms fly back too far — stop at a comfortable stretch. Control the return.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [inclineDBPressID, benchPressID]
            ),

            Exercise(
                id: hammerCurlID,
                name: "Hammer Curls",
                primaryMuscles: ["Biceps"],
                secondaryMuscles: ["Brachialis", "Brachioradialis"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Neutral-grip dumbbell curl. Targets the brachialis for arm thickness and grip strength.",
                formCues: "Neutral grip — palms face each other throughout. Don't rotate the wrist. Same rules as a regular curl — elbows pinned, no swinging. Works well alternating or simultaneously.",
                isBodyweight: false,
                suggestedStartWeightLbs: 20,
                alternativeIDs: [bicepCurlID]
            ),

            Exercise(
                id: ohTricepExtID,
                name: "Overhead Tricep Extension",
                primaryMuscles: ["Triceps"],
                secondaryMuscles: [],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "EZ-bar or dumbbell tricep extension with arms overhead. Puts the long head of the tricep under a stretched position for maximum growth.",
                formCues: "Elbows stay pointed straight up. Only the forearms move. Keep upper arms close to your head. Full extension at the top, comfortable stretch at the bottom.",
                isBodyweight: false,
                suggestedStartWeightLbs: 30,
                alternativeIDs: [tricepPushdownID]
            ),

            // ── Accessory – Lower ───────────────────────────────────────────

            Exercise(
                id: legExtensionID,
                name: "Leg Extension",
                primaryMuscles: ["Quads"],
                secondaryMuscles: [],
                tier: .accessory,
                bodyRegion: "lower",
                movementDescription: "Machine leg extension. Isolates the quadriceps through knee extension.",
                formCues: "Sit fully back in the seat. Toes slightly back for full quad engagement at lockout. Don't swing the weight — control both directions. Full lockout at the top if your knees allow.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [hackSquatID]
            ),

            Exercise(
                id: calfRaiseID,
                name: "Calf Raises",
                primaryMuscles: ["Calves"],
                secondaryMuscles: ["Soleus"],
                tier: .accessory,
                bodyRegion: "lower",
                movementDescription: "Standing or seated calf raise. Full range of motion from full stretch to full contraction.",
                formCues: "Full stretch at the bottom — let the heel drop below the platform level. Rise all the way to full plantar flexion. Hold 1 second at the top. Calves respond well to slow, controlled reps and high volume.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: []
            ),

            Exercise(
                id: hipThrustID,
                name: "Hip Thrust",
                primaryMuscles: ["Glutes"],
                secondaryMuscles: ["Hamstrings", "Core"],
                tier: .accessory,
                bodyRegion: "lower",
                movementDescription: "Barbell hip thrust with upper back on a bench. Excellent for glute isolation and development.",
                formCues: "Upper back across the bench, feet flat on the floor about hip-width. Drive hips straight up — squeeze glutes hard at the top. Don't hyperextend the lower back. Keep chin tucked slightly.",
                isBodyweight: false,
                suggestedStartWeightLbs: 45,
                alternativeIDs: [romanianDLID, legCurlID]
            ),

            Exercise(
                id: walkingLungesID,
                name: "Walking Lunges",
                primaryMuscles: ["Quads"],
                secondaryMuscles: ["Glutes", "Hamstrings", "Core"],
                tier: .accessory,
                bodyRegion: "lower",
                movementDescription: "Alternating step lunges across a distance. Excellent for single-leg strength and coordination.",
                formCues: "Step long enough that your front knee stays behind your toes. Back knee gently taps the floor. Stay tall — don't lean forward. Drive through the front heel to rise.",
                isBodyweight: false,
                suggestedStartWeightLbs: 20,
                alternativeIDs: [bulgarianSSID, legPressID]
            ),

            // ── Core / Abs ──────────────────────────────────────────────────

            Exercise(
                id: cableCrunchID,
                name: "Cable Crunch",
                primaryMuscles: ["Abs"],
                secondaryMuscles: ["Hip Flexors"],
                tier: .accessory,
                bodyRegion: "core",
                movementDescription: "Kneeling crunch using a cable with rope attachment. Allows progressive loading of the abs unlike most bodyweight alternatives.",
                formCues: "Kneel facing the cable stack, rope behind your head. Crunch down with your elbows aiming toward your knees. Round your lower back fully — don't just hip-hinge. Squeeze hard at the bottom.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [hangingLegRaiseID, declineSitUpID]
            ),

            Exercise(
                id: hangingLegRaiseID,
                name: "Hanging Leg Raise",
                primaryMuscles: ["Abs"],
                secondaryMuscles: ["Hip Flexors", "Lats"],
                tier: .accessory,
                bodyRegion: "core",
                movementDescription: "Hanging from a bar, raise legs to parallel or higher. One of the best lower ab and hip flexor exercises.",
                formCues: "Dead hang to start. Raise legs together — keep them straight for more difficulty, bent for easier. Avoid swinging. Lower with control. Posterior tilt your pelvis at the top for max ab contraction.",
                isBodyweight: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [cableCrunchID, abWheelRolloutID]
            ),

            Exercise(
                id: abWheelRolloutID,
                name: "Ab Wheel Rollout",
                primaryMuscles: ["Abs"],
                secondaryMuscles: ["Lats", "Shoulders", "Lower Back"],
                tier: .accessory,
                bodyRegion: "core",
                movementDescription: "Rolling out with an ab wheel from a kneeling position. An advanced core anti-extension exercise.",
                formCues: "Start kneeling with hands on wheel directly below shoulders. Brace your core hard before rolling. Roll out as far as you can without your lower back arching. Pull the wheel back using your abs and lats.",
                isBodyweight: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [cableCrunchID, plankID]
            ),

            Exercise(
                id: plankID,
                name: "Plank",
                primaryMuscles: ["Abs"],
                secondaryMuscles: ["Glutes", "Shoulders", "Lower Back"],
                tier: .accessory,
                bodyRegion: "core",
                movementDescription: "Isometric hold on forearms and toes. Fundamental anti-extension core exercise for stability.",
                formCues: "Forearms flat, elbows under shoulders. Body forms a straight line — no sagging hips or raised butt. Squeeze glutes and abs simultaneously. Breathe normally. Progress by adding time.",
                isBodyweight: true,
                isTimeBased: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [abWheelRolloutID]
            ),

            Exercise(
                id: russianTwistID,
                name: "Russian Twist",
                primaryMuscles: ["Obliques"],
                secondaryMuscles: ["Abs", "Hip Flexors"],
                tier: .accessory,
                bodyRegion: "core",
                movementDescription: "Seated rotational exercise targeting the obliques. Can be loaded with a weight plate or medicine ball.",
                formCues: "Lean back to about 45°. Feet off the ground or resting on floor. Rotate fully side to side — touch the weight to the ground each side. Keep your lower back from rounding excessively.",
                isBodyweight: false,
                suggestedStartWeightLbs: 10,
                alternativeIDs: [cableCrunchID, hangingLegRaiseID]
            ),

            Exercise(
                id: declineSitUpID,
                name: "Decline Sit-Up",
                primaryMuscles: ["Abs"],
                secondaryMuscles: ["Hip Flexors"],
                tier: .accessory,
                bodyRegion: "core",
                movementDescription: "Sit-up on a decline bench, increasing range of motion and resistance compared to flat floor sit-ups.",
                formCues: "Secure feet, cross arms over chest or hold weight at chest. Lower all the way down under control. Come up until torso is perpendicular to the floor. Don't use momentum — controlled movement throughout.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [cableCrunchID, hangingLegRaiseID]
            ),

            // ── Compound / Program-Specific ─────────────────────────────────

            Exercise(
                id: conventionalDLID,
                name: "Conventional Deadlift",
                primaryMuscles: ["Hamstrings", "Glutes"],
                secondaryMuscles: ["Lower Back", "Traps", "Quads", "Core"],
                tier: .anchor,
                bodyRegion: "lower",
                movementDescription: "Barbell pulled from the floor to hip lockout. The king of posterior chain exercises and a primary strength marker.",
                formCues: "Bar over mid-foot, hip-width stance. Hinge down, grip just outside your legs. Big breath and brace before pulling. Bar stays close — drag it up your shins. Push the floor away, then drive hips through at lockout.",
                isBodyweight: false,
                suggestedStartWeightLbs: 135,
                alternativeIDs: [romanianDLID, hipThrustID]
            ),

            Exercise(
                id: closeGripBenchID,
                name: "Close-Grip Bench Press",
                primaryMuscles: ["Triceps"],
                secondaryMuscles: ["Chest", "Front Delt"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Barbell bench press with a shoulder-width or slightly narrower grip to emphasize the triceps over the chest.",
                formCues: "Grip just inside shoulder-width — not too narrow (wrist strain). Same setup as regular bench: retract shoulder blades, feet flat. Tuck elbows closer to body (about 45°). Full range of motion.",
                isBodyweight: false,
                suggestedStartWeightLbs: 75,
                alternativeIDs: [tricepPushdownID, dipsID]
            ),

            Exercise(
                id: arnoldPressID,
                name: "Arnold Press",
                primaryMuscles: ["Front Delt", "Lateral Delt"],
                secondaryMuscles: ["Triceps", "Rear Delt"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Dumbbell shoulder press with rotation through the range of motion, invented by Arnold Schwarzenegger. Hits all three deltoid heads.",
                formCues: "Start with palms facing you (like the top of a curl). As you press up, rotate so palms face forward at the top. Reverse on the way down. Keep the movement smooth — don't rush the rotation.",
                isBodyweight: false,
                suggestedStartWeightLbs: 25,
                alternativeIDs: [ohpID, dbShoulderPressID]
            ),

            Exercise(
                id: dbPulloverID,
                name: "Dumbbell Pullover",
                primaryMuscles: ["Lats"],
                secondaryMuscles: ["Chest", "Triceps", "Serratus"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Lying across or along a bench, lower a dumbbell overhead and pull it back. Classic Arnold Split exercise for lat and chest development.",
                formCues: "Lie perpendicular to the bench, upper back supported. Hold one dumbbell with both hands above your chest. Maintain a slight elbow bend. Lower behind your head until you feel a stretch, pull back to start.",
                isBodyweight: false,
                suggestedStartWeightLbs: 30,
                alternativeIDs: [pullUpsID, cableRowID]
            ),

            Exercise(
                id: tBarRowID,
                name: "T-Bar Row",
                primaryMuscles: ["Upper Back", "Lats"],
                secondaryMuscles: ["Biceps", "Rear Delt", "Lower Back"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Barbell row with one end anchored and the other loaded. Allows heavy loading with a neutral grip option for back thickness.",
                formCues: "Straddle the bar, hinge forward to about 45°. Neutral or pronated grip. Pull to your lower chest. Lead with your elbows, not your hands. Squeeze shoulder blades at the top. Control the descent.",
                isBodyweight: false,
                suggestedStartWeightLbs: 45,
                alternativeIDs: [barbellRowID, cableRowID]
            ),

            Exercise(
                id: preacherCurlID,
                name: "Preacher Curl",
                primaryMuscles: ["Biceps"],
                secondaryMuscles: ["Brachialis"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "EZ-bar or dumbbell curl on a preacher bench. Eliminates momentum and provides a strong stretch at the bottom.",
                formCues: "Upper arms fully on the pad, don't lift your arms off at the top. Full range — let the weight fully extend at the bottom. Squeeze at the top. Use lighter weight than regular curls — there's nowhere to cheat.",
                isBodyweight: false,
                suggestedStartWeightLbs: 30,
                alternativeIDs: [bicepCurlID, hammerCurlID]
            ),

            // ── User-Requested Additions ─────────────────────────────────────

            Exercise(
                id: seatedOHPID,
                name: "Seated Barbell Shoulder Press",
                primaryMuscles: ["Front Delt"],
                secondaryMuscles: ["Lateral Delt", "Triceps", "Upper Chest"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Barbell overhead press performed seated. The fixed base eliminates leg drive and core compensation, placing maximum demand on the deltoids and triceps.",
                formCues: "Set the bench to 90° and sit with your back fully supported. Unrack the bar at upper-chest height with a grip just outside shoulder-width. Brace your core — don't arch your lower back away from the pad. Press straight up to lockout, then lower under control to just below chin height. Keep wrists stacked over elbows throughout.",
                isBodyweight: false,
                suggestedStartWeightLbs: 55,
                alternativeIDs: [ohpID, dbShoulderPressID, arnoldPressID]
            ),

            Exercise(
                id: bicycleCrunchID,
                name: "Bicycle Crunch",
                primaryMuscles: ["Obliques"],
                secondaryMuscles: ["Abs", "Hip Flexors"],
                tier: .accessory,
                bodyRegion: "core",
                movementDescription: "Alternating elbow-to-knee crunch performed on the floor. One of the most effective exercises for the obliques and upper abs when done with full rotation and control.",
                formCues: "Hands lightly behind your head — don't pull on your neck. Bring one knee in while rotating the opposite elbow toward it. Fully extend the other leg low to the ground. The rotation should come from your torso, not your elbow. Slow and controlled — avoid rushing through the reps. Aim for 15–20 reps per side per set.",
                isBodyweight: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [russianTwistID, cableCrunchID]
            ),

            Exercise(
                id: reverseCrunchID,
                name: "Reverse Crunch",
                primaryMuscles: ["Abs"],
                secondaryMuscles: ["Hip Flexors"],
                tier: .accessory,
                bodyRegion: "core",
                movementDescription: "Lying floor exercise where the hips curl up toward the chest rather than the torso curling up. Targets the lower portion of the rectus abdominis.",
                formCues: "Lie flat, arms at your sides or gripping something behind your head for stability. Start with legs raised to 90°. Curl your hips off the floor by contracting your lower abs — not by swinging. Your knees should move toward your chest, not straight up. Lower slowly back to the start. Keep the movement small and deliberate.",
                isBodyweight: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [hangingLegRaiseID, cableCrunchID]
            ),

            Exercise(
                id: benchDipsID,
                name: "Bench Dips",
                primaryMuscles: ["Triceps"],
                secondaryMuscles: ["Front Delt", "Chest"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Tricep dip using a flat bench for support. Hands on the bench behind you, lower your body toward the floor and press back up. Can be progressed by elevating the feet or adding a weight plate on the lap.",
                formCues: "Hands shoulder-width on the bench edge, fingers forward. Keep your hips close to the bench as you lower. Lower until elbows reach 90° — don't go deeper to protect the shoulder joint. Press straight back up to full extension. Keep your torso upright — leaning forward shifts load to the chest. For added resistance, place a weight plate on your thighs.",
                isBodyweight: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [dipsID, tricepPushdownID, ohTricepExtID]
            ),

            // ── Researched Additions ─────────────────────────────────────────

            Exercise(
                id: latPulldownID,
                name: "Lat Pulldown",
                primaryMuscles: ["Lats"],
                secondaryMuscles: ["Biceps", "Rear Delt", "Teres Major"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Cable machine pull of a wide bar to the upper chest. The primary vertical pulling alternative to pull-ups for lat width and thickness.",
                formCues: "Sit with thighs locked under the pad. Lean back very slightly (about 10°). Pull the bar to your upper chest — not behind your neck. Lead with your elbows, driving them down and back. Squeeze lats at the bottom. Slow, controlled return to full arm extension.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [pullUpsID, closeGripLatPulldownID]
            ),

            Exercise(
                id: closeGripLatPulldownID,
                name: "Close-Grip Lat Pulldown",
                primaryMuscles: ["Lats"],
                secondaryMuscles: ["Biceps", "Lower Traps"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Lat pulldown using a narrow neutral-grip attachment. The closer grip allows a greater range of motion and stronger bicep involvement.",
                formCues: "Use a V-bar or parallel grip. Sit upright or with a very slight lean back. Pull the handle toward your sternum. Squeeze the lats hard at the bottom — feel the contraction before releasing. Full extension at the top.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [latPulldownID, cableRowID]
            ),

            Exercise(
                id: singleArmDBRowID,
                name: "Single-Arm Dumbbell Row",
                primaryMuscles: ["Upper Back", "Lats"],
                secondaryMuscles: ["Biceps", "Rear Delt"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Unilateral dumbbell row with one hand and knee on a bench. Allows heavy loading and a full range of motion on each side independently.",
                formCues: "Place the same-side knee and hand on the bench for support. Keep your back flat and parallel to the floor. Pull the dumbbell toward your hip, not your shoulder. Let the arm fully extend at the bottom for a full stretch. Don't rotate your torso to cheat the weight up.",
                isBodyweight: false,
                suggestedStartWeightLbs: 45,
                alternativeIDs: [barbellRowID, cableRowID]
            ),

            Exercise(
                id: chestSupportedRowID,
                name: "Chest-Supported Row",
                primaryMuscles: ["Upper Back"],
                secondaryMuscles: ["Biceps", "Rear Delt", "Lower Traps"],
                tier: .secondary,
                bodyRegion: "upper",
                movementDescription: "Dumbbell or barbell row with the chest on an incline bench, eliminating lower back involvement and momentum.",
                formCues: "Set bench to 30–45°. Lie chest-down. Let arms hang fully at the bottom. Pull dumbbells toward your hips, squeezing shoulder blades together. The chest support removes the temptation to heave — use strict form and feel the back working.",
                isBodyweight: false,
                suggestedStartWeightLbs: 30,
                alternativeIDs: [barbellRowID, singleArmDBRowID]
            ),

            Exercise(
                id: seatedCableFlyLowID,
                name: "Cable Fly (Low to High)",
                primaryMuscles: ["Chest"],
                secondaryMuscles: ["Front Delt"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Cable fly with the pulleys set low, sweeping the arms up and across the body. Targets the upper chest and provides constant tension through the full arc.",
                formCues: "Set cables at the lowest position. Stand centered between the stacks. Slight lean forward, soft bend in the elbows. Drive your hands up and together in an arc — like hugging a barrel. Squeeze chest at the top when hands meet. Control the return slowly.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [cableChestFlyeID, inclineDBPressID]
            ),

            Exercise(
                id: skullCrushersID,
                name: "Skull Crushers",
                primaryMuscles: ["Triceps"],
                secondaryMuscles: [],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Lying EZ-bar or dumbbell tricep extension to the forehead or behind the head. Excellent for the long and medial heads of the triceps.",
                formCues: "Lie flat on a bench, upper arms vertical. Lower the bar to your forehead (or slightly behind) by bending only at the elbows. Keep upper arms still — if they drift, reduce the weight. Press back to full extension. Use an EZ-bar to reduce wrist strain.",
                isBodyweight: false,
                suggestedStartWeightLbs: 40,
                alternativeIDs: [ohTricepExtID, tricepPushdownID]
            ),

            Exercise(
                id: concentrationCurlID,
                name: "Concentration Curl",
                primaryMuscles: ["Biceps"],
                secondaryMuscles: ["Brachialis"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Seated unilateral curl with the elbow braced against the inner thigh. Eliminates momentum entirely and forces peak bicep contraction.",
                formCues: "Sit on a bench, lean forward. Brace the back of your upper arm against your inner thigh. Curl all the way up and squeeze hard at the top. Lower slowly. Don't let the elbow drift — the thigh brace is the point. 3–4 sets of 10–15 reps per arm.",
                isBodyweight: false,
                suggestedStartWeightLbs: 20,
                alternativeIDs: [bicepCurlID, preacherCurlID]
            ),

            Exercise(
                id: inclineDBCurlID,
                name: "Incline Dumbbell Curl",
                primaryMuscles: ["Biceps"],
                secondaryMuscles: ["Brachialis"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Dumbbell curl performed on an incline bench. The arm hangs behind the body, providing a longer stretch and peak bicep activation.",
                formCues: "Set bench to 45–60°. Sit back and let arms hang straight down. Curl both or alternately, keeping elbows back (don't let them drift forward). Supinate at the top. The stretch at the bottom is the point — don't cut the range short.",
                isBodyweight: false,
                suggestedStartWeightLbs: 20,
                alternativeIDs: [bicepCurlID, concentrationCurlID]
            ),

            Exercise(
                id: sumoDeadliftID,
                name: "Sumo Deadlift",
                primaryMuscles: ["Glutes", "Hamstrings"],
                secondaryMuscles: ["Quads", "Lower Back", "Traps", "Core"],
                tier: .anchor,
                bodyRegion: "lower",
                movementDescription: "Wide-stance deadlift with toes pointed out. Shorter range of motion than conventional, with greater glute and quad involvement.",
                formCues: "Stance wide — feet outside hip-width, toes pointed out 30–45°. Grip inside your legs. Push your knees out in line with your toes before pulling. Chest tall, hips lower than conventional. Drive your feet into the floor like you're spreading the floor apart. Lock out hips and knees simultaneously.",
                isBodyweight: false,
                suggestedStartWeightLbs: 135,
                alternativeIDs: [conventionalDLID, romanianDLID, hipThrustID]
            ),

            Exercise(
                id: frontSquatID,
                name: "Front Squat",
                primaryMuscles: ["Quads"],
                secondaryMuscles: ["Glutes", "Core", "Upper Back"],
                tier: .anchor,
                bodyRegion: "lower",
                movementDescription: "Barbell squat with the bar held in the front rack position. Demands an upright torso and strong upper back, with greater quad activation than back squat.",
                formCues: "Bar rests on front delts, fingertips on the bar (clean grip) or arms crossed. Elbows high throughout — if they drop, the bar rolls forward. Stay very upright; front squats punish any forward lean. Hit depth: hip crease below knees. Drive knees out as you stand.",
                isBodyweight: false,
                suggestedStartWeightLbs: 75,
                alternativeIDs: [backSquatID, gobletSquatID]
            ),

            Exercise(
                id: goodMorningsID,
                name: "Good Mornings",
                primaryMuscles: ["Hamstrings"],
                secondaryMuscles: ["Glutes", "Lower Back", "Erectors"],
                tier: .secondary,
                bodyRegion: "lower",
                movementDescription: "Barbell on the upper back, hinge forward until the torso is close to parallel with the floor. A powerful hamstring and lower back strengthener.",
                formCues: "Light weight — this exercise gets heavy fast. Soft bend in the knees. Hinge from the hips, not the waist. Keep your back flat: a rounded lower back here is dangerous. Lower until you feel a strong hamstring stretch. Drive hips forward to return. Never use momentum.",
                isBodyweight: false,
                suggestedStartWeightLbs: 45,
                alternativeIDs: [romanianDLID, conventionalDLID]
            ),

            Exercise(
                id: nordicHamstringCurlID,
                name: "Nordic Hamstring Curl",
                primaryMuscles: ["Hamstrings"],
                secondaryMuscles: ["Glutes", "Calves"],
                tier: .secondary,
                bodyRegion: "lower",
                movementDescription: "Kneel with feet anchored, lower your torso toward the floor using only hamstring strength. One of the most effective hamstring strengthening and injury prevention exercises.",
                formCues: "Kneel on a pad, ankles secured under a bar or with a partner. Body stays rigid like a plank — don't bend at the hips. Lower as slowly as possible using hamstring tension. Catch yourself with your hands, then use hands to push back up for the first few reps. As you progress, rely on hands less. 3–4 sets of 4–8 reps.",
                isBodyweight: true,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [legCurlID, romanianDLID]
            ),

            Exercise(
                id: cableGluteKickbackID,
                name: "Cable Glute Kickback",
                primaryMuscles: ["Glutes"],
                secondaryMuscles: ["Hamstrings"],
                tier: .accessory,
                bodyRegion: "lower",
                movementDescription: "Ankle cuff attached to a low cable pulley, kick the leg back to full hip extension. Isolates the glutes with constant cable tension.",
                formCues: "Attach ankle cuff to the low cable. Stand facing the stack, hold the frame for balance. Hinge forward slightly from the hips. Kick the leg directly back — not out to the side. Squeeze the glute hard at full extension. Keep hips square; don't rotate. Slow, controlled return. 3–4 sets of 12–15 reps per side.",
                isBodyweight: false,
                suggestedStartWeightLbs: nil,
                alternativeIDs: [hipThrustID, walkingLungesID]
            ),

            Exercise(
                id: dbShrugsID,
                name: "Dumbbell Shrugs",
                primaryMuscles: ["Traps"],
                secondaryMuscles: ["Neck", "Levator Scapulae"],
                tier: .accessory,
                bodyRegion: "upper",
                movementDescription: "Standing dumbbell shrug targeting the upper trapezius. Simple and effective for building trap thickness.",
                formCues: "Hold dumbbells at your sides, arms straight. Shrug straight up — think about touching your shoulders to your ears. No rolling of the shoulders (forward/backward circles add no benefit and risk injury). Hold 1 second at the top. Lower slowly. 3–4 sets of 12–15 reps.",
                isBodyweight: false,
                suggestedStartWeightLbs: 40,
                alternativeIDs: [facePullID, barbellRowID]
            ),
        ]
    }
}
