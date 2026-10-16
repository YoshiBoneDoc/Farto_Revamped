import TeresMimicDiet.ash;

// Compatibility entry: the retired simulator now previews the sole production planner.
// Historical comments remain verbatim; optimizer implementations are in checkpoint 6b679da.
// Read-only preview: selectors and price lookups only, never gameplay requests.

void barfSimulation(){barfDietPlan();}
