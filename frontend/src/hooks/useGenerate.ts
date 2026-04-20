import { useMutation, useQueryClient } from "@tanstack/react-query";
import { generateArtifact } from "../services/api";

export function useGenerate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: generateArtifact,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["usage"] });
      queryClient.invalidateQueries({ queryKey: ["history"] });
    },
  });
}
