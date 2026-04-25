import { useMutation, useQueryClient } from "@tanstack/react-query";
import { batchGenerate } from "../services/api";

export function useBatchGenerate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: batchGenerate,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["usage"] });
      queryClient.invalidateQueries({ queryKey: ["history"] });
    },
  });
}
