<template>
  <div>
    <div class="page-header">
      <h2>용어사전</h2>
      <p>테이블 컬럼 표준 용어 정의 ({{ total.toLocaleString() }}건)</p>
    </div>

    <div class="filter-bar">
      <el-input v-model="search" placeholder="논리명, 물리명, 영문의미 검색..." clearable style="width: 350px;"
        @keyup.enter="fetchData" @clear="fetchData">
        <template #prefix><el-icon><Search /></el-icon></template>
      </el-input>
      <el-select v-model="groupFilter" placeholder="도메인그룹" clearable @change="fetchData" style="width: 130px;">
        <el-option v-for="g in domainGroups" :key="g.group_id" :label="g.group_name" :value="g.group_id" />
      </el-select>
      <el-select v-model="typeFilter" placeholder="데이터유형" clearable @change="fetchData" style="width: 130px;">
        <el-option label="VARCHAR" value="VARCHAR" />
        <el-option label="NUMERIC" value="NUMERIC" />
        <el-option label="CHAR" value="CHAR" />
        <el-option label="DATE" value="DATE" />
        <el-option label="CLOB" value="CLOB" />
        <el-option label="BLOB" value="BLOB" />
      </el-select>
      <el-checkbox v-model="piiFilter" label="개인정보만" @change="fetchData" />
      <el-button type="primary" @click="fetchData"><el-icon><Search /></el-icon> 조회</el-button>
    </div>

    <div class="table-card">
      <div class="card-header">
        <h3>용어 목록</h3>
        <span style="color: var(--el-text-color-regular); font-size: 13px;">총 {{ total.toLocaleString() }}건</span>
      </div>
      <el-table :data="items" v-loading="loading" stripe style="width: 100%;" @sort-change="handleSort">
        <el-table-column prop="term_id" label="ID" width="70" sortable="custom" />
        <el-table-column prop="logical_name" label="논리명" width="200" sortable="custom" show-overflow-tooltip />
        <el-table-column prop="physical_name" label="물리명" width="220" sortable="custom" show-overflow-tooltip />
        <el-table-column prop="english_name" label="영문의미" min-width="250" show-overflow-tooltip />
        <el-table-column prop="domain_abbr" label="도메인약어" width="100" align="center" />
        <el-table-column prop="data_type" label="유형" width="100" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.data_type" size="small">{{ row.data_type }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="data_length" label="길이" width="70" align="center" />
        <el-table-column prop="is_personal_info" label="PII" width="55" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.is_personal_info" type="danger" size="small">Y</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="is_encrypted" label="암호화" width="65" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.is_encrypted" type="warning" size="small">Y</el-tag>
          </template>
        </el-table-column>
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
import { termApi, domainApi } from '@/api'

const items = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const page = ref(1)
const pageSize = ref(50)
const search = ref('')
const groupFilter = ref<number | null>(null)
const typeFilter = ref('')
const piiFilter = ref(false)
const sortBy = ref<string | null>(null)
const order = ref('asc')
const domainGroups = ref<any[]>([])

async function fetchData() {
  loading.value = true
  try {
    const params: any = { page: page.value, size: pageSize.value }
    if (search.value) params.search = search.value
    if (groupFilter.value) params.domain_group_id = groupFilter.value
    if (typeFilter.value) params.data_type = typeFilter.value
    if (piiFilter.value) params.is_personal_info = true
    if (sortBy.value) { params.sort_by = sortBy.value; params.order = order.value }

    const res = await termApi.list(params)
    items.value = res.data.items
    total.value = res.data.total
  } catch (e) {
    console.error('용어 조회 실패:', e)
  } finally {
    loading.value = false
  }
}

function handleSort({ prop, order: sortOrder }: any) {
  sortBy.value = prop
  order.value = sortOrder === 'descending' ? 'desc' : 'asc'
  fetchData()
}

onMounted(async () => {
  try {
    const res = await domainApi.listGroups()
    domainGroups.value = res.data
  } catch (e) { /* ignore */ }
  fetchData()
})
</script>
