<template>
  <div>
    <div class="page-header">
      <h2>단어사전</h2>
      <p>K-water 표준 단어 정의 ({{ total.toLocaleString() }}건)</p>
    </div>

    <!-- 필터 -->
    <div class="filter-bar">
      <el-input
        v-model="search"
        placeholder="논리명, 물리명, 설명 검색..."
        clearable
        style="width: 300px;"
        @keyup.enter="fetchData"
        @clear="fetchData"
      >
        <template #prefix><el-icon><Search /></el-icon></template>
      </el-input>
      <el-select v-model="classFilter" placeholder="속성분류어" clearable @change="fetchData" style="width: 150px;">
        <el-option label="분류어(Y)" :value="true" />
        <el-option label="비분류어(N)" :value="false" />
      </el-select>
      <el-button type="primary" @click="fetchData">
        <el-icon><Search /></el-icon> 조회
      </el-button>
    </div>

    <!-- 테이블 -->
    <div class="table-card">
      <div class="card-header">
        <h3>단어 목록</h3>
        <span style="color: var(--el-text-color-regular); font-size: 13px;">
          총 {{ total.toLocaleString() }}건
        </span>
      </div>
      <el-table
        :data="items"
        v-loading="loading"
        stripe
        style="width: 100%;"
        @sort-change="handleSort"
      >
        <el-table-column prop="word_id" label="ID" width="70" sortable="custom" />
        <el-table-column prop="logical_name" label="논리명" width="200" sortable="custom" />
        <el-table-column prop="physical_name" label="물리명" width="180" sortable="custom" />
        <el-table-column prop="physical_desc" label="물리의미" min-width="200" />
        <el-table-column prop="is_class_word" label="분류어" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.is_class_word ? 'success' : 'info'" size="small">
              {{ row.is_class_word ? 'Y' : 'N' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="synonym" label="동의어" width="150" />
        <el-table-column prop="status" label="상태" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'danger'" size="small">
              {{ row.status }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
      <div style="padding: 16px; display: flex; justify-content: center;">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[20, 50, 100, 200]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="fetchData"
          @current-change="fetchData"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { wordApi } from '@/api'

const items = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const page = ref(1)
const pageSize = ref(50)
const search = ref('')
const classFilter = ref<boolean | null>(null)
const sortBy = ref<string | null>(null)
const order = ref('asc')

async function fetchData() {
  loading.value = true
  try {
    const params: any = { page: page.value, size: pageSize.value }
    if (search.value) params.search = search.value
    if (classFilter.value !== null && classFilter.value !== '') params.is_class_word = classFilter.value
    if (sortBy.value) { params.sort_by = sortBy.value; params.order = order.value }

    const res = await wordApi.list(params)
    items.value = res.data.items
    total.value = res.data.total
  } catch (e) {
    console.error('단어 조회 실패:', e)
  } finally {
    loading.value = false
  }
}

function handleSort({ prop, order: sortOrder }: any) {
  sortBy.value = prop
  order.value = sortOrder === 'descending' ? 'desc' : 'asc'
  fetchData()
}

onMounted(fetchData)
</script>
