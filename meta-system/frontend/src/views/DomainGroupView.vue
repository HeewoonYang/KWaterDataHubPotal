<template>
  <div>
    <div class="page-header">
      <h2>도메인그룹</h2>
      <p>데이터 도메인 분류 ({{ groups.length }}건)</p>
    </div>

    <div class="table-card">
      <el-table :data="groups" v-loading="loading" stripe style="width: 100%;">
        <el-table-column prop="group_id" label="ID" width="70" />
        <el-table-column prop="group_name" label="도메인그룹명" width="200" />
        <el-table-column prop="sort_order" label="정렬순서" width="100" align="center" />
        <el-table-column prop="is_active" label="활성" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'danger'" size="small">
              {{ row.is_active ? '활성' : '비활성' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="설명" min-width="200" />
      </el-table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { domainApi } from '@/api'

const groups = ref<any[]>([])
const loading = ref(false)

onMounted(async () => {
  loading.value = true
  try {
    const res = await domainApi.listGroups()
    groups.value = res.data
  } catch (e) {
    console.error('도메인그룹 조회 실패:', e)
  } finally {
    loading.value = false
  }
})
</script>
