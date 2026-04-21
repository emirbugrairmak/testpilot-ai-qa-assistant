import { useMutation, useQueryClient } from "@tanstack/react-query";
import { deleteHistoryItem } from "../services/api";

export function useDeleteHistory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: deleteHistoryItem,
    onSuccess: (_, generationId) => {
      queryClient.invalidateQueries({ queryKey: ["history"] });
      queryClient.removeQueries({ queryKey: ["history-detail", generationId] });
    },
  });
}
