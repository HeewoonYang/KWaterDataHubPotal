<template>
  <div class="app-layout">
    <!-- 사이드바 -->
    <aside class="app-sidebar">
      <div class="logo">
        <div class="logo-icon">M</div>
        <span>메타데이터 표준사전</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        router
        :collapse="false"
      >
        <el-menu-item index="/">
          <el-icon><DataBoard /></el-icon>
          <span>대시보드</span>
        </el-menu-item>

        <el-sub-menu index="dict">
          <template #title>
            <el-icon><Collection /></el-icon>
            <span>표준사전</span>
          </template>
          <el-menu-item index="/words">단어사전</el-menu-item>
          <el-menu-item index="/domain-groups">도메인그룹</el-menu-item>
          <el-menu-item index="/domains">도메인사전</el-menu-item>
          <el-menu-item index="/terms">용어사전</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="code">
          <template #title>
            <el-icon><List /></el-icon>
            <span>코드사전</span>
          </template>
          <el-menu-item index="/code-groups">코드그룹</el-menu-item>
          <el-menu-item index="/codes">코드값 조회</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="manage">
          <template #title>
            <el-icon><Setting /></el-icon>
            <span>관리</span>
          </template>
          <el-menu-item index="/import-export">임포트/엑스포트</el-menu-item>
          <el-menu-item index="/history">변경이력</el-menu-item>
        </el-sub-menu>
      </el-menu>
    </aside>

    <!-- 메인 영역 -->
    <div class="app-main">
      <header class="app-header">
        <h1 style="font-size: 16px; font-weight: 600; color: var(--el-text-color-primary);">
          K-water DataHub 메타데이터 관리
        </h1>
        <div style="display: flex; align-items: center; gap: 12px;">
          <el-tag type="info" size="small">v1.0.0</el-tag>
        </div>
      </header>

      <main class="app-content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  DataBoard, Collection, List, Setting,
} from '@element-plus/icons-vue'

const route = useRoute()
const activeMenu = computed(() => route.path)
</script>
