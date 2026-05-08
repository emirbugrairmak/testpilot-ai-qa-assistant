export type Plan = "free" | "premium";

export type GenerationMode = "mod_a" | "mod_b" | "bug_report";
export type ExportFormat = "json" | "markdown" | "pdf" | "csv" | "jira";

export type AuthValidateResponse = {
  valid: boolean;
  plan: Plan;
  owner_name: string;
  issued_via?: string | null;
  monthly_limit: number;
  usage_count: number;
  remaining: number;
  usage_resets_at: string;
};

export type FreeAccessCreateRequest = {
  owner_name?: string;
};

export type PremiumAccessCreateRequest = {
  owner_name: string;
  plan_summary?: string;
};

export type AccessKeyCreateResponse = {
  access_key: string;
  plan: Plan;
  owner_name: string;
  issued_via: string;
  monthly_limit: number;
  usage_count: number;
  remaining: number;
  usage_resets_at: string;
  created_at: string;
};

export type UsageResponse = {
  plan: Plan;
  monthly_limit: number;
  usage_count: number;
  remaining: number;
  usage_reset_at: string;
};

export type SystemStatusResponse = {
  status: string;
  service: string;
  version: string;
  ai: {
    configured_provider: "mock" | "gemini" | string;
    effective_provider: "mock" | "gemini" | string;
    model: string;
    fallback_to_mock: boolean;
    gemini_key_configured: boolean;
  };
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

export type HistoryQueryParams = {
  mode?: GenerationMode | "all";
  q?: string;
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
      template_id?: number;
    }
  | {
      mode: "mod_b";
      user_story: string;
      acceptance_criteria: string;
      template_id?: number;
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
      template_id?: number;
    };

export type GenerateResponse = {
  generation_id: number;
  mode: GenerationMode;
  provider?: string;
  user_story?: string;
  acceptance_criteria?: string[];
  test_plan?: TestPlan;
  test_cases?: TestCase[];
  bug_report?: BugReport;
  tags?: string[];
  markdown?: string;
  watermark?: string;
  plan_stamp?: {
    plan: "free";
    label: string;
    note?: string;
    notice?: string;
    source?: string;
  } | null;
  created_at: string;
};

export type HistoryDetailResponse = {
  generation_id: number;
  mode: GenerationMode;
  input: Record<string, unknown>;
  output: Omit<GenerateResponse, "generation_id">;
  markdown: string;
  created_at: string;
};

export type DeleteHistoryResponse = {
  deleted: boolean;
  generation_id: number;
};

export type Template = {
  id: number;
  name: string;
  prompt_text: string;
  created_at: string;
  updated_at: string;
};

export type TemplateListResponse = {
  items: Template[];
  count: number;
};

export type TemplatePayload = {
  name: string;
  prompt_text: string;
};

export type BatchGenerateItem =
  | {
      feature_idea: string;
      template_id?: number;
    }
  | {
      user_story: string;
      acceptance_criteria: string;
      template_id?: number;
    };

export type BatchGenerateRequest = {
  mode: "mod_a" | "mod_b";
  items: BatchGenerateItem[];
  template_id?: number;
};

export type BatchResultItem = {
  index: number;
  success: boolean;
  generation_id?: number | null;
  result?: GenerateResponse | Record<string, unknown> | null;
  error?: string | null;
};

export type BatchGenerateResponse = {
  mode: "mod_a" | "mod_b";
  total_items: number;
  success_count: number;
  failed_count: number;
  results: BatchResultItem[];
};
