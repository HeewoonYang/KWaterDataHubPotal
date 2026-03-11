<template>
  <div>
    <div class="page-header">
      <h2>변경이력</h2>
      <p>표준사전 변경 추적 기록</p>
    </div>

    <div class="filter-bar">
      <el-select v-model="dictType" placeholder="사전 유형" clearable @change="fetchData" style="width: 150px;">
        <el-option label="단어사전" value="word" />
        <el-option label="도메인그룹" value="domain_group" />
        <el-option label="도메인사전" value="domain" />
        <el-option label="용어사전" value="term" />
        <el-option label="코드그룹" value="code_group" />
        <el-option label="코드사전" value="code" />
      </el-select>
      <el-button type="primary" @click="fetchData"><el-icon><Search /></el-icon> 조회</el-button>
    </div>

    <div class="table-card">
      <div class="card-header">
        <h3>변경이력 목록</h3>
        <span style="color: var(--el-text-color-regular); font-size: 13px;">총 {{ total.toLocaleString() }}건</span>
      </div>
      <el-table :data="items" v-loading="loading" stripe style="width: 100%;">
        <el-table-column prop="history_id" label="ID" width="80" />
        <el-table-column prop="dict_type" label="사전유형" width="120">
          <template #default="{ row }">
            <el-tag size="small">{{ dictTypeLabel(row.dict_type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="record_id" label="레코드ID" width="100" />
        <el-table-column prop="action" label="변경유형" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="actionType(row.action)" size="small">{{ row.action }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="change_desc" label="변경설명" min-width="250" show-overflow-tooltip />
        <el-table-column prop="changed_by" label="변경자" width="120" />
        <el-table-column prop="changed_at" label="변경일시" width="180" />
      </el-table>
      <div style="padding: 16px; display: flex; justify-content: center;">
        <el-pagination v-model:current-page="page" v-model:page-size="pageSize" :total="total"
          :page-sizes="[20, 50, 100]" layout="total, sizes, prev, pager, next, jumper"
          @size-change="fetchData" @current-change="fetchData" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { importExportApi } from '@/api'

const items = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const page = ref(1)
const pageSize = ref(50)
const dictType = ref('')

const dictTypeLabels: Record<string, string> = {
  word: '단어', domain_group: '도메인그룹', domain: '도메인',
  term: '용어', code_group: '코드그룹', code: '코드',
}

function dictTypeLabel(type: string) { return dictTypeLabels[type] || type }
function actionType(action: string) {
  const map: Record<string, string> = { create: 'success', update: 'warning', delete: 'danger', import: 'info' }
  return map[action] || 'info'
}

async function fetchData() {
  loading.value = true
  try {
    const params: any = { page: page.value, size: pageSize.value }
    if (dictType.value) params.dict_type = dictType.value
    const res = await importExportApi.history(params)
    items.value = res.data.items
    total.value = res.data.total
  } catch (e) {
    console.error('이력 조회 실패:', e)
  } finally {
    loading.value = false
  }
}

onMounted(fetchData)
</script>
