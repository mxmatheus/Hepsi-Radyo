import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function fixMojibake(text: string): string {
  if (!text) return text
  return text
    .replaceAll('Ä±', 'ı')
    .replaceAll('Ä°', 'İ')
    .replaceAll('ÅŸ', 'ş')
    .replaceAll('ÅŞ', 'Ş')
    .replaceAll('Ã§', 'ç')
    .replaceAll('Ã‡', 'Ç')
    .replaceAll('Ã¼', 'ü')
    .replaceAll('Ãœ', 'Ü')
    .replaceAll('Ã¶', 'ö')
    .replaceAll('Ã–', 'Ö')
    .replaceAll('ÄŸ', 'ğ')
    .replaceAll('ÄĞ', 'Ğ')
}

function decodeStreamTitle(buffer: Uint8Array): string {
  // 1. Try UTF-8 first
  try {
    const utf8Str = new TextDecoder('utf-8', { fatal: true }).decode(buffer)
    const match = utf8Str.match(/StreamTitle='([^']+)';/)
    if (match && match[1]) {
      return fixMojibake(match[1].trim())
    }
  } catch (_) {}

  // 2. Try Windows-1254 (Turkish)
  try {
    const win1254Str = new TextDecoder('windows-1254').decode(buffer)
    const match = win1254Str.match(/StreamTitle='([^']+)';/)
    if (match && match[1]) {
      return fixMojibake(match[1].trim())
    }
  } catch (_) {}

  // 3. Fallback ISO-8859-1 (latin1)
  try {
    const latin1Str = new TextDecoder('latin1').decode(buffer)
    const match = latin1Str.match(/StreamTitle='([^']+)';/)
    if (match && match[1]) {
      return fixMojibake(match[1].trim())
    }
  } catch (_) {}

  return ""
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { stream_url } = await req.json()
    if (!stream_url) {
      return new Response(
        JSON.stringify({ error: 'stream_url parameter is required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 4000)

    const response = await fetch(stream_url, {
      headers: {
        'Icy-MetaData': '1',
        'User-Agent': 'VLC/3.0.18 LibVLC/3.0.18'
      },
      signal: controller.signal
    })

    clearTimeout(timeoutId)

    const metaintHeader = response.headers.get('icy-metaint')
    const stationNameHeader = response.headers.get('icy-name')

    if (!metaintHeader || !response.body) {
      return new Response(
        JSON.stringify({
          supported: false,
          station_name: stationNameHeader || null,
          title: null,
          artist: null,
          song: null
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    const metaint = parseInt(metaintHeader, 10)
    const reader = response.body.getReader()
    let bytesRead = 0
    let metadataTitle = ""

    while (bytesRead < metaint + 4096) {
      const { value, done } = await reader.read()
      if (done || !value) break
      bytesRead += value.length

      if (bytesRead > metaint) {
        metadataTitle = decodeStreamTitle(value)
        if (metadataTitle) break
      }
    }

    reader.cancel()

    metadataTitle = fixMojibake(metadataTitle)

    let artist = null
    let song = null
    if (metadataTitle.includes('-')) {
      const parts = metadataTitle.split('-')
      artist = fixMojibake(parts[0].trim())
      song = fixMojibake(parts.slice(1).join('-').trim())
    } else if (metadataTitle.length > 0) {
      song = metadataTitle
    }

    return new Response(
      JSON.stringify({
        supported: true,
        station_name: stationNameHeader || null,
        raw_title: metadataTitle,
        artist: artist,
        song: song || metadataTitle
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ supported: false, error: (error as Error).message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  }
})
