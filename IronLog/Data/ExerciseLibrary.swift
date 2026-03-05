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
        ]
    }
}
