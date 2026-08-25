export function checkNPM(document) {
  if (typeof document === 'object') {
    return window.qusto?.s === 'npm'
  }

  return false
}
