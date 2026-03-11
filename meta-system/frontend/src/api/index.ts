/**
 * API 클라이언트 (Axios)
 */
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// 응답 인터셉터 — 에러 처리
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const message = error.response?.data?.detail || '서버 요청 중 오류가 발생했습니다.'
    console.error('[API 오류]', message)
    return Promise.reject(error)
  }
)

export default apiClient

// ============================================================================
// API 함수들
// ============================================================================

/** 페이지네이션 응답 타입 */
export interface PageResponse<T> {
  items: T[]
  total: number
  page: number
  size: number
  pages: number
}

// --- 단어사전 ---
export const wordApi = {
  list: (params: Record<string, any>) => apiClient.get<PageResponse<any>>('/words', { params }),
  get: (id: number) => apiClient.get(`/words/${id}`),
  create: (data: any) => apiClient.post('/words', data),
  update: (id: number, data: any) => apiClient.put(`/words/${id}`, data),
  delete: (id: number) => apiClient.delete(`/words/${id}`),
}

// --- 도메인사전 ---
export const domainApi = {
  listGroups: () => apiClient.get('/domain-groups'),
  getGroup: (id: number) => apiClient.get(`/domain-groups/${id}`),
  list: (params: Record<string, any>) => apiClient.get<PageResponse<any>>('/domains', { params }),
  get: (id: number) => apiClient.get(`/domains/${id}`),
  create: (data: any) => apiClient.post('/domains', data),
  update: (id: number, data: any) => apiClient.put(`/domains/${id}`, data),
  delete: (id: number) => apiClient.delete(`/domains/${id}`),
}

// --- 용어사전 ---
export const termApi = {
  list: (params: Record<string, any>) => apiClient.get<PageResponse<any>>('/terms', { params }),
  get: (id: number) => apiClient.get(`/terms/${id}`),
  create: (data: any) => apiClient.post('/terms', data),
  update: (id: number, data: any) => apiClient.put(`/terms/${id}`, data),
  delete: (id: number) => apiClient.delete(`/terms/${id}`),
}

// --- 코드사전 ---
export const codeApi = {
  listGroups: (params: Record<string, any>) => apiClient.get<PageResponse<any>>('/code-groups', { params }),
  getGroup: (id: number) => apiClient.get(`/code-groups/${id}`),
  listPrefixes: () => apiClient.get('/code-groups/prefixes'),
  listCodes: (params: Record<string, any>) => apiClient.get<PageResponse<any>>('/codes', { params }),
  getCode: (id: number) => apiClient.get(`/codes/${id}`),
  getTree: (groupId: number) => apiClient.get(`/codes/tree/${groupId}`),
  createCode: (data: any) => apiClient.post('/codes', data),
  updateCode: (id: number, data: any) => apiClient.put(`/codes/${id}`, data),
  deleteCode: (id: number) => apiClient.delete(`/codes/${id}`),
}

// --- 통계 ---
export const statsApi = {
  summary: () => apiClient.get('/stats/summary'),
  domainDistribution: () => apiClient.get('/stats/domain-distribution'),
  dataTypes: () => apiClient.get('/stats/data-types'),
  codeGroups: () => apiClient.get('/stats/code-groups'),
}

// --- 임포트/엑스포트 ---
export const importExportApi = {
  importExcel: (dictType: string, file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    return apiClient.post(`/import/${dictType}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      timeout: 120000,
    })
  },
  exportExcel: (dictType: string) =>
    apiClient.get(`/export/${dictType}`, { responseType: 'blob' }),
  history: (params: Record<string, any>) => apiClient.get('/history', { params }),
}
