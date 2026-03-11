<template>
  <div>
    <div class="page-header">
      <h2>도메인사전</h2>
      <p>데이터 도메인 표준 정의 ({{ total.toLocaleString() }}건)</p>
    </div>

    <div class="filter-bar">
      <el-input v-model="search" placeholder="도메인명, 논리명 검색..." clearable style="width: 300px;"
        @keyup.enter="fetchData" @clear="fetchData">
        <template #prefix><el-icon><Search /></el-icon></template>
      </el-input>
      <el-select v-model="groupFilter" placeholder="도메인그룹" clearable @change="fetchData" style="width: 150px;">
        <el-option v-for="g in domainGroups" :key="g.group_id" :label="g.group_name" :value="g.group_id" />
      </el-select>
      <el-select v-model="typeFilter" placeholder="데이터유형" clearable @change="fetchData" style="width: 140px;">
        <el-option label="NUMERIC" value="NUMERIC" />
        <el-option label="VARCHAR" value="VARCHAR" />
        <el-option label="CHAR" value="CHAR" />
        <el-option label="DATE" value="DATE" />
        <el-option label="TIMESTAMP" value="TIMESTAMP" />
        <el-option label="BLOB" value="BLOB" />
        <el-option label="CLOB" value="CLOB" />
        <el-option label="GEOMETRY" value="GEOMETRY" />
      </el-select>
      <el-button type="primary" @click="fetchData"><el-icon><Search /></el-icon> 조회</el-button>
    </div>

    <div class="table-card">
      <div class="card-header">
        <h3>도메인 목록</h3>
        <span style="color: var(--el-text-color-regular); font-size: 13px;">총 {{ total.toLocaleString() }}건</span>
      </div>
      <el-table :data="items" v-loading="loading" stripe style="width: 100%;">
        <el-table-column prop="domain_id" label="ID" width="70" />
        <el-table-column prop="domain_name" label="도메인명" width="200" />
        <el-table-column prop="domain_logical_name" label="도메인논리명" width="220" />
        <el-table-column prop="data_type" label="데이터유형" width="120" align="center">
          <template #default="{ row }">
            <el-tag size="small">{{ row.data_type }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="data_length" label="길이" width="80" align="center" />
        <el-table-column prop="data_scale" label="소수점" width="80" align="center" />
        <el-table-column prop="is_personal_info" label="PII" width="60" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.is_personal_info" type="danger" size="small">Y</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="설명" min-width="200" show-overflow-tooltip />
      </el-table>
      <div style="padding: 16px; display: flex; justify-content: center;">
        <el-pagination v-model:current-page="page" v-model:page-size="pageSize" :total="total"
          :page-sizes="[20, 50, 100, 200]" layout="total, sizes, prev, pager, next, jumper"
          @size-change="fetchData" @current-change="fetchData" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { domainApi } from '@/api'

const items = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const page = ref(1)
const pageSize = ref(50)
const search = ref('')
const groupFilter = ref<number | null>(null)
const typeFilter = ref('')
const domainGroups = ref<any[]>([])

async function fetchData() {
  loading.value = true
  try {
    const params: any = { page: page.value, size: pageSize.value }
    if (search.value) params.search = search.value
    if (groupFilter.value) params.group_id = groupFilter.value
    if (typeFilter.value) params.data_type = typeFilter.value

    const res = await domainApi.list(params)
    items.value = res.data.items
    total.value = res.data.total
  } catch (e) {
    console.error('도메인 조회 실패:', e)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  try {
    const res = await domainApi.listGroups()
    domainGroups.value = res.data
  } catch (e) {
    console.error('도메인그룹 로드 실패:', e)
  }
  fetchData()
})
</script>
