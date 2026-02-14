/** Sets up the tracking library. Can be called once. */
export function init(config: QustoConfig): void

/** Tracks an event, requires `init` to be called first. */
export function track(eventName: string, options: QustoEventOptions): void

export interface QustoConfig {
  /** Your site's domain, as declared by you in Qusto's settings. */
  domain: string

  /**
   * The URL of the Qusto API endpoint. Defaults to https://qusto.io/api/event
   * See proxying guide at https://qusto.io/docs/proxy/introduction
   */
  endpoint?: string

  /** Whether to automatically capture pageviews. Defaults to true. */
  autoCapturePageviews?: boolean

  /**
   * Whether the page uses hash based routing. Defaults to false.
   * Read more at https://qusto.io/docs/hash-based-routing
   */
  hashBasedRouting?: boolean

  /** Whether to track outbound link clicks. Defaults to false. */
  outboundLinks?: boolean

  /** Whether to track file downloads. Defaults to false. */
  fileDownloads?: boolean | { fileExtensions: string[] }

  /** Whether to track form submissions. Defaults to false. */
  formSubmissions?: boolean

  /** Whether to capture events on localhost. Defaults to false. */
  captureOnLocalhost?: boolean

  /** Whether to log on ignored events. Defaults to true. */
  logging?: boolean

  /**
   * Custom properties to add to all events tracked.
   * If passed as a function, it will be called when `track` is called.
   */
  customProperties?:
    | CustomProperties
    | ((eventName: string) => CustomProperties)

  /**
   * A function that can be used to transform the payload before it is sent to the API.
   * If the function returns null or any other falsy value, the event will be ignored.
   *
   * This can be used to avoid sending certain types of events, or modifying any event
   * parameters, e.g. to clean URLs of values that should not be recorded.
   */
  transformRequest?: (
    payload: QustoRequestPayload
  ) => QustoRequestPayload | null

  /**
   * If enabled (the default), the script will set `window.plausible` after `init` is called.
   * This is used by the verifier to detect if the script is loaded from npm package.
   */
  bindToWindow?: boolean
}

export interface QustoEventOptions {
  /**
   * Custom properties to add to the event.
   * Read more at https://qusto.io/docs/custom-props/introduction
   */
  props?: CustomProperties

  /**
   * Whether the tracked event is interactive. Defaults to true.
   * By marking a custom event as non-interactive, it will not be counted towards bounce rate calculations.
   */
  interactive?: boolean

  /**
   * Revenue data to add to the event.
   * Read more at https://qusto.io/docs/ecommerce-revenue-tracking
   */
  revenue?: QustoEventRevenue

  /**
   * Called when request to `endpoint` completes or is ignored.
   * When request is ignored, the result will be undefined.
   * When request was delivered, the result will be an object with the response status code of the request.
   * When there was a network error, the result will be an object with the error object.
   */
  callback?: (
    result?: { status: number } | { error: unknown } | undefined
  ) => void

  /**
   * Overrides the URL of the page that the event is being tracked on.
   * If not provided, `location.href` will be used.
   */
  url?: string
}

export type CustomProperties = Record<string, string>

export type QustoEventRevenue = {
  /** Revenue amount in `currency` */
  amount: number | string
  /** Currency is an ISO 4217 string representing the currency code, e.g. "USD" or "EUR" */
  currency: string
}

export type QustoRequestPayload = {
  /** Event name */
  n: string
  /** URL of the event */
  u: string
  /** Domain of the event */
  d: string
  /** Referrer */
  r?: string | null
  /** Custom properties */
  p?: CustomProperties
  /** Revenue information */
  $?: QustoEventRevenue
  /** Whether the event is interactive */
  i?: boolean
} & Record<string, unknown>

/** Default file types that are tracked when `fileDownloads` is enabled. */
export const DEFAULT_FILE_TYPES: string[]
