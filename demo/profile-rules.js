"use strict";
(function (host) {
  const allowedTypes = new Set(["image/png", "image/jpeg", "image/webp"]);
  function validateAvatarFile(file) {
    if (!file || !allowedTypes.has(file.type)) return "Chọn ảnh PNG, JPEG hoặc WebP.";
    if (file.size < 1 || file.size > 2 * 1024 * 1024) return "Ảnh cần có dung lượng tối đa 2 MB.";
    return null;
  }
  function validateAvatarDimensions(width, height) {
    return Number.isInteger(width) && Number.isInteger(height) &&
      width >= 64 && height >= 64 && width <= 4096 && height <= 4096;
  }
  const rules = {validateAvatarFile, validateAvatarDimensions};
  if (typeof module !== "undefined" && module.exports) module.exports = rules;
  host.ProfileRules = rules;
})(typeof window !== "undefined" ? window : globalThis);
