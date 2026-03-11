<template>
  <div>
    <div class="page-header">
      <h2>대시보드</h2>
      <p>K-water 메타데이터 표준사전 현황</p>
    </div>

    <!-- KPI 카드 -->
    <div class="kpi-grid">
      <div class="kpi-card" v-for="dict in summary.dictionaries" :key="dict.type">
        <div class="kpi-label">{{ dict.name }}</div>
        <div class="kpi-value">{{ dict.count?.toLocaleString() || 0 }}</div>
        <div class="kpi-sub">건</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">전체 레코드</div>
        <div class="kpi-value" style="color: var(--el-color-primary);">
          {{ summary.total_records?.toLocaleString() || 0 }}
        </div>
        <div class="kpi-sub">건</div>
      </div>
    </div>

    <!-- 도메인그룹 분포 -->
    <div class="table-card" style="margin-bottom: 20px;">
      <div class="card-header">
        <h3>도메인그룹별 도메인 분포</h3>
      </div>
      <el-table :data="domainDist" stripe style="width: 100%;">
        <el-table-column prop="group_name" label="도메인그룹" width="150" />
        <el-table-column prop="domain_count" label="도메인 수" width="120" align="center" />
        <el-table-column label="비율">
          <template #default="{ row }">
            <el-progress
              :percentage="domainTotal > 0 ? Math.round(row.domain_count / domainTotal * 100) : 0"
              :stroke-width="16"
              :text-inside="true"
            />
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 데이터유형 분포 -->
    <div class="table-card">
      <div class="card-header">
        <h3>데이터유형별 분포</h3>
      </div>
      <el-table :data="dataTypes.domain_types || []" stripe style="width: 100%;">
        <el-table-column prop="data_type" label="데이터유형" width="200" />
        <el-table-column prop="count" label="도메인 건수" align="center" />
      </el-table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { statsApi } from '@/api'

const summary = ref<any>({ dictionaries: [], total_records: 0 })
const domainDist = ref<any[]>([])
const dataTypes = ref<any>({ domain_types: [], term_types: [] })

const domainTotal = computed(() =>
  domainDist.value.reduce((sum: number, d: any) => sum + (d.domain_count || 0), 0)
)

onMounted(async () => {
  try {
    const [summaryRes, distRes, typesRes] = await Promise.all([
      statsApi.summary(),
      statsApi.domainDistribution(),
      statsApi.dataTypes(),
    ])
    summary.value = summaryRes.data
    domainDist.value = distRes.data
    dataTypes.value = typesRes.data
  } catch (e) {
    console.error('대시보드 데이터 로드 실패:', e)
  }
})
</script>
