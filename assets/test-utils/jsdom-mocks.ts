import { configMocks } from 'jsdom-testing-mocks'
import { act } from '@testing-library/react'

// as per jsdom-testing-mocks docs, this is needed to avoid having to wrap everything in act calls
configMocks({ act })

// react-router v7 uses TextEncoder/TextDecoder internally for URL parsing.
// jest-environment-jsdom does not expose them as globals on the window object
// even though Node >=18 has them. Polyfill from Node's built-in 'util' module.
import { TextEncoder, TextDecoder } from 'util'
Object.assign(global, { TextEncoder, TextDecoder })
