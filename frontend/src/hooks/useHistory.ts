import { useQuery } from "@tanstack/react-query";
import { fetchHistory } from "../services/api";
import type { HistoryQueryParams } from "../types/api";

export function useHistory(params: HistoryQueryParams, enabled: boolean) {
  return useQuery({
    queryKey: ["history", params],
    queryFn: () => fetchHistory(params),
    enabled,
  });
}
