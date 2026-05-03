const BASE_URL = 'http://localhost:5000'

async function request(method, path, body = null) {
  const options = {
    method,
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include', // sends session cookie with every request
  }
  if (body) options.body = JSON.stringify(body)
  const res = await fetch(`${BASE_URL}${path}`, options)
  const data = await res.json()
  if (!res.ok) throw new Error(data.error || 'Request failed')
  return data
}

export const api = {
  // Auth
  register: (body) => request('POST', '/api/auth/register', body),
  login: (body) => request('POST', '/api/auth/login', body),
  logout: () => request('POST', '/api/auth/logout'),
  getMe: () => request('GET', '/api/auth/me'),

  // Profile
  updateProfile: (id, body) => request('PUT', `/api/users/${id}`, body),
  uploadPhoto: (id, formData) => {
    return fetch(`${BASE_URL}/api/users/${id}/photo`, {
      method: 'POST',
      credentials: 'include',
      body: formData, // FormData, not JSON
    }).then(r => r.json())
  },

  // Search & Discovery 
  searchUsers: (params = {}) => {
    const query = new URLSearchParams()
    if (params.min_age) query.set('min_age', params.min_age)
    if (params.max_age) query.set('max_age', params.max_age)
    if (params.city) query.set('city', params.city)
    if (params.interests?.length) query.set('interests', params.interests.join(','))
    if (params.looking_for) query.set('looking_for', params.looking_for)
    if (params.max_distance_km) query.set('max_distance_km', params.max_distance_km)
    if (params.sort) query.set('sort', params.sort)
    if (params.page) query.set('page', params.page)
    return request('GET', `/api/search?${query.toString()}`)
  },

  // Matching
  interact: (target_id, action) => request('POST', '/api/interact', { target_id, action }),
  getMatches: () => request('GET', '/api/matches'),
}