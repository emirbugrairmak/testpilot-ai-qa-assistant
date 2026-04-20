import { useQuery } from "@tanstack/react-query";
import { fetchUsage } from "../services/api";

export function useUsage(enabled: boolean) {
  return useQuery({
    queryKey: ["usage"],
    queryFn: fetchUsage,
    enabled,
  });
}
