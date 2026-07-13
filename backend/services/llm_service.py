import os
import httpx
import asyncio
from typing import List, Dict, Optional
from services.key_rotator import key_rotator

async def generate_gemini_content(
    system_instruction: str,
    history: List[Dict[str, str]],
    user_message: str,
    image_base64: Optional[str] = None,
    temperature: float = 0.7
) -> tuple[str, str]:
    """
    Sends request to Gemini 1.5 Flash REST API with dynamic system instructions,
    multimodal inputs, temperature overrides, and automatic key rotation on failure.
    Returns:
        tuple[reply_text, api_key_used]
    """
    
    # 1. Format contents array for Gemini API (uses 'user' and 'model' roles)
    contents = []
    for turn in history:
        role = "user" if turn["role"] == "user" else "model"
        contents.append({
            "role": role,
            "parts": [{"text": turn["content"]}]
        })
        
    # Append the active user turn (including image if present)
    current_parts = []
    if image_base64:
        # Strip potential data:image/...;base64, headers
        clean_base64 = image_base64
        if "," in image_base64:
            clean_base64 = image_base64.split(",")[1]
            
        current_parts.append({
            "inlineData": {
                "mimeType": "image/jpeg",
                "data": clean_base64
            }
        })
        
    if user_message:
        current_parts.append({"text": user_message})
        
    contents.append({
        "role": "user",
        "parts": current_parts
    })
    
    # Payload base config
    payload = {
        "contents": contents,
        "systemInstruction": {
            "parts": [{"text": system_instruction}]
        },
        "generationConfig": {
            "temperature": temperature,
            "maxOutputTokens": 256  # keep response short and punchy
        }
    }
    
    max_retries = 3
    for attempt in range(max_retries):
        active_key = key_rotator.get_active_key()
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={active_key}"
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, timeout=5.0)
                
                # If key is rate limited (429), invalid (400/403), or server has transient issues (500/502/503/504)
                if response.status_code in [429, 400, 403, 500, 502, 503, 504]:
                    key_rotator.mark_cooldown(active_key)
                    # Introduce a 1-second delay for transient server errors to allow recovery
                    if response.status_code in [500, 502, 503, 504]:
                        await asyncio.sleep(1.0)
                    continue
                    
                response.raise_for_status()
                data = response.json()
                
                # Extract response text
                candidates = data.get("candidates", [])
                if not candidates:
                    raise Exception("Gemini API returned no text candidates.")
                    
                reply_text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                return reply_text.strip(), active_key
                
            except httpx.HTTPStatusError as e:
                # Mark key on cooldown and retry
                key_rotator.mark_cooldown(active_key)
                if attempt == max_retries - 1:
                    break
                # Small sleep before retry
                await asyncio.sleep(1.0)
            except Exception as e:
                if attempt == max_retries - 1:
                    break
                await asyncio.sleep(1.0)
                    
    # Try local FreeLLMAPI backup proxy if direct calls failed
    try:
        base_url = os.getenv("OPENAI_API_BASE", "https://my-freellmapi-proxy.onrender.com/v1").rstrip("/")
        proxy_url = f"{base_url}/chat/completions"
        api_key = os.getenv("OPENAI_API_KEY", "freellmapi-ec75ec409b980a3248a3b64f0a702afb51781feb35d3ec23")
        proxy_headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        proxy_messages = [{"role": "system", "content": system_instruction}]
        for turn in history:
            proxy_messages.append({
                "role": turn["role"],
                "content": turn["content"]
            })
            
        if image_base64:
            clean_base64 = image_base64
            if "," in image_base64:
                clean_base64 = image_base64.split(",")[1]
            proxy_messages.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": user_message},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{clean_base64}"
                        }
                    }
                ]
            })
        else:
            proxy_messages.append({
                "role": "user",
                "content": user_message
            })
            
        proxy_payload = {
            "model": "gemini-2.5-flash",
            "messages": proxy_messages,
            "temperature": temperature,
            "max_tokens": 256
        }
        
        async with httpx.AsyncClient() as client:
            proxy_res = await client.post(proxy_url, json=proxy_payload, headers=proxy_headers, timeout=30.0)
            proxy_res.raise_for_status()
            proxy_data = proxy_res.json()
            reply_text = proxy_data["choices"][0]["message"]["content"]
            return reply_text.strip(), "freellmapi-proxy-backup"
    except Exception as proxy_err:
        raise Exception(f"All rotation and fallback keys failed to respond successfully. Proxy also failed: {proxy_err}")

async def generate_summary(history: List[Dict[str, str]]) -> str:
    """
    Sends conversational history to Gemini to retrieve a single sentence summary.
    Used for memory compression on session end.
    """
    system_instruction = (
        "You are an assistant that summarizes conversations in one concise sentence. "
        "Summarize the main topic discussed, the user's overall mood, and any major events mentioned. "
        "Write in third person (e.g., 'The user venting about project stresses and was tired')."
    )
    
    # Map turns
    contents = []
    for turn in history:
        role = "user" if turn["role"] == "user" else "model"
        contents.append({
            "role": role,
            "parts": [{"text": turn["content"]}]
        })
        
    contents.append({
        "role": "user",
        "parts": [{"text": "Summarize this entire chat history in one clear sentence."}]
    })
    
    payload = {
        "contents": contents,
        "systemInstruction": {
            "parts": [{"text": system_instruction}]
        },
        "generationConfig": {
            "temperature": 0.3, # low temperature for accurate summary
            "maxOutputTokens": 128
        }
    }
    
    # Fetch key and send request
    active_key = key_rotator.get_active_key()
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={active_key}"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=payload, timeout=5.0)
            response.raise_for_status()
            data = response.json()
            reply_text = data["candidates"][0]["content"]["parts"][0]["text"]
            return reply_text.strip()
        except Exception as e:
            # Fall back to FreeLLMAPI proxy for summary
            try:
                base_url = os.getenv("OPENAI_API_BASE", "https://my-freellmapi-proxy.onrender.com/v1").rstrip("/")
                proxy_url = f"{base_url}/chat/completions"
                api_key = os.getenv("OPENAI_API_KEY", "freellmapi-ec75ec409b980a3248a3b64f0a702afb51781feb35d3ec23")
                proxy_headers = {
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                }
                proxy_messages = [{"role": "system", "content": system_instruction}]
                for turn in history:
                    proxy_messages.append({
                        "role": turn["role"],
                        "content": turn["content"]
                    })
                proxy_messages.append({
                    "role": "user",
                    "content": "Summarize this entire chat history in one clear sentence."
                })
                proxy_payload = {
                    "model": "gemini-2.5-flash",
                    "messages": proxy_messages,
                    "temperature": 0.3,
                    "max_tokens": 128
                }
                response = await client.post(proxy_url, json=proxy_payload, headers=proxy_headers, timeout=20.0)
                response.raise_for_status()
                data = response.json()
                return data["choices"][0]["message"]["content"].strip()
            except Exception as proxy_err:
                return f"Failed to generate summary: {str(e)} (Proxy fallback also failed: {str(proxy_err)})"
