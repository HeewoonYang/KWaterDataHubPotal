<template>
  <div>
    <div class="page-header">
      <h2>임포트 / 엑스포트</h2>
      <p>엑셀 파일 업로드 및 다운로드</p>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
      <!-- 임포트 카드 -->
      <div class="table-card">
        <div class="card-header">
          <h3>엑셀 임포트</h3>
        </div>
        <div style="padding: 20px;">
          <el-form label-position="top">
            <el-form-item label="사전 유형">
              <el-select v-model="importType" placeholder="사전 유형 선택" style="width: 100%;">
                <el-option label="단어사전" value="word" />
                <el-option label="도메인사전" value="domain" />
                <el-option label="용어사전" value="term" />
              </el-select>
            </el-form-item>
            <el-form-item label="엑셀 파일 (.xlsx)">
              <el-upload
                ref="uploadRef"
                :auto-upload="false"
                :limit="1"
                accept=".xlsx"
                @change="handleFileChange"
              >
                <el-button>파일 선택</el-button>
              </el-upload>
            </el-form-item>
            <el-button type="primary" @click="handleImport" :loading="importing" :disabled="!importType || !importFile"
              style="width: 100%;">
              임포트 실행
            </el-button>
          </el-form>

          <!-- 임포트 결과 -->
          <el-result v-if="importResult" :icon="importResult.error_count > 0 ? 'warning' : 'success'"
            :title="importResult.message" style="margin-top: 16px;">
            <template #extra>
              <p>성공: {{ importResult.success_count }}건 / 실패: {{ importResult.error_count }}건</p>
            </template>
          </el-result>
        </div>
      </div>

      <!-- 엑스포트 카드 -->
      <div class="table-card">
        <div class="card-header">
          <h3>엑셀 엑스포트</h3>
        </div>
        <div style="padding: 20px;">
          <p style="margin-bottom: 16px; color: var(--el-text-color-regular);">
            현재 DB에 저장된 사전 데이터를 엑셀 파일로 다운로드합니다.
          </p>
          <div style="display: flex; flex-direction: column; gap: 12px;">
            <el-button @click="handleExport('word')" :loading="exporting === 'word'">
              단어사전 다운로드
            </el-button>
            <el-button @click="handleExport('domain')" :loading="exporting === 'domain'">
              도메인사전 다운로드
            </el-button>
            <el-button @click="handleExport('term')" :loading="exporting === 'term'">
              용어사전 다운로드
            </el-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { importExportApi } from '@/api'
import { ElMessage } from 'element-plus'

const importType = ref('')
const importFile = ref<File | null>(null)
const importing = ref(false)
const importResult = ref<any>(null)
const exporting = ref('')

function handleFileChange(file: any) {
  importFile.value = file.raw
}

async function handleImport() {
  if (!importType.value || !importFile.value) return
  importing.value = true
  importResult.value = null
  try {
    const res = await importExportApi.importExcel(importType.value, importFile.value)
    importResult.value = res.data
    ElMessage.success(res.data.message)
  } catch (e: any) {
    ElMessage.error(e.response?.data?.detail || '임포트 중 오류가 발생했습니다.')
  } finally {
    importing.value = false
  }
}

async function handleExport(dictType: string) {
  exporting.value = dictType
  try {
    const res = await importExportApi.exportExcel(dictType)
    const url = window.URL.createObjectURL(new Blob([res.data]))
    const link = document.createElement('a')
    link.href = url
    link.download = `meta_${dictType}_export.xlsx`
    link.click()
    window.URL.revokeObjectURL(url)
    ElMessage.success(`${dictType} 엑스포트 완료`)
  } catch (e) {
    ElMessage.error('엑스포트 중 오류가 발생했습니다.')
  } finally {
    exporting.value = ''
  }
}
</script>
