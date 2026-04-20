import { useQuery } from "@tanstack/react-query";
import { fetchHistory } from "../services/api";

export function useHistory(enabled: boolean) {
  return useQuery({
    queryKey: ["history"],
    queryFn: fetchHistory,
    enabled,
  });
}
