import { useQuery } from "@tanstack/react-query";
import { fetchTemplates } from "../services/api";

export function useTemplates(enabled: boolean) {
  return useQuery({
    queryKey: ["templates"],
    queryFn: fetchTemplates,
    enabled,
  });
}
