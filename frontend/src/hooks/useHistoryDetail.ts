import { useQuery } from "@tanstack/react-query";
import { fetchHistoryDetail } from "../services/api";

export function useHistoryDetail(generationId: number | null, enabled: boolean) {
  return useQuery({
    queryKey: ["history-detail", generationId],
    queryFn: () => fetchHistoryDetail(generationId as number),
    enabled: enabled && generationId !== null,
  });
}
