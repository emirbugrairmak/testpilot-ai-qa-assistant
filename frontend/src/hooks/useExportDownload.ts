import { useMutation } from "@tanstack/react-query";
import { downloadExportFile } from "../services/api";
import type { ExportFormat } from "../types/api";

type DownloadVariables = {
  generationId: number;
  format: ExportFormat;
};

export function useExportDownload() {
  return useMutation({
    mutationFn: async ({ generationId, format }: DownloadVariables) => {
      const file = await downloadExportFile(generationId, format);
      const url = URL.createObjectURL(file.blob);
      const anchor = document.createElement("a");

      anchor.href = url;
      anchor.download = file.filename;
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      window.setTimeout(() => URL.revokeObjectURL(url), 1000);

      return file.filename;
    },
  });
}
