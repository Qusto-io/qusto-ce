export function checkNPM(document) {
  if (typeof document === 'object') {
    return window.qusto?.s === 'npm' || window.plausible?.s === 'npm'
  }

  return false
}
