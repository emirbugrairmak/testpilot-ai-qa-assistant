export type Plan = "free" | "premium";

export type GenerationMode = "mod_a" | "mod_b" | "bug_report";

export type AuthValidateResponse = {
  valid: boolean;
  plan: Plan;
  owner_name: string;
  monthly_limit: number;
  usage_count: number;
  remaining: number;
  usage_resets_at: string;
};

export type UsageResponse = {
  plan: Plan;
  monthly_limit: number;
  usage_count: number;
  remaining: number;
  usage_reset_at: string;
};

export type HistoryItem = {
  generation_id: number;
  mode: GenerationMode;
  input: Record<string, unknown>;
  output_summary: string;
  created_at: string;
};

export type HistoryListResponse = {
  items: HistoryItem[];
  count: number;
  plan: Plan;
  limit?: number | null;
};

export type TestPlan = {
  objective: string;
  scope: string;
  test_types: string[];
  approach: string;
};

export type TestCase = {
  id: string;
  title: string;
  type: string;
  priority: string;
  preconditions: string;
  steps: string[];
  expected_result: string;
  tags: string[];
};

export type BugReport = {
  title: string;
  summary: string;
  severity: string;
  priority: string;
  environment: string;
  steps_to_reproduce: string[];
  actual_result: string;
  expected_result: string;
  labels: string[];
};

export type GenerateRequest =
  | {
      mode: "mod_a";
      feature_idea: string;
    }
  | {
      mode: "mod_b";
      user_story: string;
      acceptance_criteria: string;
    }
  | {
      mode: "bug_report";
      title?: string;
      summary?: string;
      steps_to_reproduce: string[];
      actual_result: string;
      expected_result: string;
      environment: string;
      severity?: string;
    };

export type GenerateResponse = {
  generation_id: number;
  mode: GenerationMode;
  user_story?: string;
  acceptance_criteria?: string[];
  test_plan?: TestPlan;
  test_cases?: TestCase[];
  bug_report?: BugReport;
  tags?: string[];
  markdown?: string;
  watermark?: string;
  created_at: string;
};
