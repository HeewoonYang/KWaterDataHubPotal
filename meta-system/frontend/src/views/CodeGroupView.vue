<template>
  <div>
    <div class="page-header">
      <h2>코드그룹</h2>
      <p>업무시스템별 공통코드 그룹 ({{ total.toLocaleString() }}건)</p>
    </div>

    <div class="filter-bar">
      <el-input v-model="search" placeholder="논리명, 물리명, 코드ID 검색..." clearable style="width: 300px;"
        @keyup.enter="fetchData" @clear="fetchData">
        <template #prefix><el-icon><Search /></el-icon></template>
      </el-input>
      <el-select v-model="prefixFilter" placeholder="시스템 접두어" clearable filterable @change="fetchData" style="width: 200px;">
        <el-option v-for="p in prefixes" :key="p.system_prefix"
          :label="`${p.system_prefix} (${p.system_name || ''})`" :value="p.system_prefix" />
      </el-select>
      <el-button type="primary" @click="fetchData"><el-icon><Search /></el-icon> 조회</el-button>
    </div>

    <div class="table-card">
      <div class="card-header">
        <h3>코드그룹 목록</h3>
        <span style="color: var(--el-text-color-regular); font-size: 13px;">총 {{ total.toLocaleString() }}건</span>
      </div>
      <el-table :data="items" v-loading="loading" stripe style="width: 100%;">
        <el-table-column prop="group_id" label="ID" width="70" />
        <el-table-column prop="system_prefix" label="시스템" width="100" align="center">
          <template #default="{ row }">
            <el-tag size="small">{{ row.system_prefix }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="system_name" label="시스템명" width="160" />
        <el-table-column prop="logical_name" label="논리명" width="200" show-overflow-tooltip />
        <el-table-column prop="physical_name" label="물리명" width="250" show-overflow-tooltip />
        <el-table-column prop="code_id" label="코드ID" width="130" />
        <el-table-column prop="code_type" label="코드구분" width="100" />
        <el-table-column prop="data_length" label="길이" width="70" align="center" />
        <el-table-column label="코드값 조회" width="100" align="center">
          <template #default="{ row }">
            <el-button size="small" type="primary" link
              @click="$router.push({ name: 'codes', query: { group_id: row.group_id } })">
              조회
            </el-button>
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
import { codeApi } from '@/api'

const items = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const page = ref(1)
const pageSize = ref(50)
const search = ref('')
const prefixFilter = ref('')
const prefixes = ref<any[]>([])

async function fetchData() {
  loading.value = true
  try {
    const params: any = { page: page.value, size: pageSize.value }
    if (search.value) params.search = search.value
    if (prefixFilter.value) params.system_prefix = prefixFilter.value

    const res = await codeApi.listGroups(params)
    items.value = res.data.items
    total.value = res.data.total
  } catch (e) {
    console.error('코드그룹 조회 실패:', e)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  try {
    const res = await codeApi.listPrefixes()
    prefixes.value = res.data
  } catch (e) { /* ignore */ }
  fetchData()
})
</script>
