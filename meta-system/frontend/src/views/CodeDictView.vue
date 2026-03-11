<template>
  <div>
    <div class="page-header">
      <h2>코드사전</h2>
      <p>공통코드 값 조회 (코드그룹 선택 필수)</p>
    </div>

    <div class="filter-bar">
      <el-select v-model="groupId" placeholder="코드그룹 선택 (필수)" filterable style="width: 400px;" @change="fetchData">
        <el-option v-for="g in codeGroups" :key="g.group_id"
          :label="`[${g.system_prefix}] ${g.logical_name} (${g.code_id})`"
          :value="g.group_id" />
      </el-select>
      <el-input v-model="search" placeholder="코드값, 코드명 검색..." clearable style="width: 250px;"
        @keyup.enter="fetchData" @clear="fetchData">
        <template #prefix><el-icon><Search /></el-icon></template>
      </el-input>
      <el-button type="primary" @click="fetchData" :disabled="!groupId"><el-icon><Search /></el-icon> 조회</el-button>
    </div>

    <!-- 선택된 코드그룹 정보 -->
    <el-alert v-if="!groupId" title="코드그룹을 선택해주세요" type="info" :closable="false"
      description="14만건 이상의 코드 데이터를 효율적으로 조회하기 위해 코드그룹 선택이 필수입니다."
      style="margin-bottom: 16px;" />

    <div class="table-card" v-if="groupId">
      <div class="card-header">
        <h3>코드값 목록</h3>
        <span style="color: var(--el-text-color-regular); font-size: 13px;">총 {{ total.toLocaleString() }}건</span>
      </div>
      <el-table :data="items" v-loading="loading" stripe style="width: 100%;">
        <el-table-column prop="code_id" label="ID" width="70" />
        <el-table-column prop="code_value" label="코드값" width="150" />
        <el-table-column prop="code_name" label="코드값명" min-width="250" show-overflow-tooltip />
        <el-table-column prop="sort_order" label="정렬" width="70" align="center" />
        <el-table-column prop="parent_code_name" label="부모코드명" width="150" show-overflow-tooltip />
        <el-table-column prop="parent_code_value" label="부모코드값" width="100" />
        <el-table-column prop="description" label="설명" width="200" show-overflow-tooltip />
        <el-table-column prop="effective_from" label="시작일" width="110" />
        <el-table-column prop="effective_to" label="종료일" width="110" />
        <el-table-column prop="status" label="상태" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'danger'" size="small">{{ row.status }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
      <div style="padding: 16px; display: flex; justify-content: center;">
        <el-pagination v-model:current-page="page" v-model:page-size="pageSize" :total="total"
          :page-sizes="[50, 100, 200]" layout="total, sizes, prev, pager, next, jumper"
          @size-change="fetchData" @current-change="fetchData" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { Search } from '@element-plus/icons-vue'
import { codeApi } from '@/api'

const route = useRoute()
const items = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const page = ref(1)
const pageSize = ref(100)
const search = ref('')
const groupId = ref<number | null>(null)
const codeGroups = ref<any[]>([])

async function fetchData() {
  if (!groupId.value) return
  loading.value = true
  try {
    const params: any = { group_id: groupId.value, page: page.value, size: pageSize.value }
    if (search.value) params.search = search.value

    const res = await codeApi.listCodes(params)
    items.value = res.data.items
    total.value = res.data.total
  } catch (e) {
    console.error('코드 조회 실패:', e)
  } finally {
    loading.value = false
  }
}

async function loadCodeGroups() {
  try {
    // 전체 코드그룹 목록 로드 (크기 제한 높임)
    const res = await codeApi.listGroups({ page: 1, size: 200 })
    codeGroups.value = res.data.items
  } catch (e) {
    console.error('코드그룹 로드 실패:', e)
  }
}

onMounted(async () => {
  await loadCodeGroups()
  // URL 쿼리로 그룹 ID가 전달된 경우 자동 선택
  if (route.query.group_id) {
    groupId.value = Number(route.query.group_id)
    fetchData()
  }
})
</script>
