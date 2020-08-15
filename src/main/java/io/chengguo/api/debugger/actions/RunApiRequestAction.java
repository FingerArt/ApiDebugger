package io.chengguo.api.debugger.actions;

import com.intellij.execution.ExecutionException;
import com.intellij.execution.ExecutionManager;
import com.intellij.execution.Executor;
import com.intellij.execution.configurations.RunProfile;
import com.intellij.execution.configurations.RunProfileState;
import com.intellij.execution.executors.DefaultRunExecutor;
import com.intellij.execution.runners.ExecutionEnvironment;
import com.intellij.execution.runners.ExecutionEnvironmentBuilder;
import com.intellij.icons.AllIcons;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.project.Project;
import io.chengguo.api.debugger.ApiDebuggerBundle;
import io.chengguo.api.debugger.lang.ApiBlockConverter;
import io.chengguo.api.debugger.lang.psi.ApiApiBlock;
import io.chengguo.api.debugger.lang.psi.ApiRequest;
import io.chengguo.api.debugger.lang.run.ApiHttpRequestRunProfileState;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;

public abstract class RunApiRequestAction extends ApiDebuggerBaseAction {

    protected final ApiApiBlock mApiBlock;

    public RunApiRequestAction(ApiApiBlock apiBlock, String env) {
        super(ApiDebuggerBundle.message("api.debugger.editor.action.run.with.env", env), ApiDebuggerBundle.message("api.debugger.editor.action.run.with.env", env), AllIcons.RunConfigurations.TestState.Run);
        mApiBlock = apiBlock;
    }

    @Override
    public String getId() {
        return "Api.Debugger.RunApiRequest";
    }

    @Override
    public void actionPerformed(@NotNull AnActionEvent e) {
        try {
            Project project = e.getProject();
            if (project == null) return;
            ApiBlockConverter.toApiBlock(mApiBlock);
            final ExecutionEnvironmentBuilder builder = ExecutionEnvironmentBuilder.create(project, DefaultRunExecutor.getRunExecutorInstance(), new RunProfile() {
                @Nullable
                @Override
                public RunProfileState getState(@NotNull Executor executor, @NotNull ExecutionEnvironment environment) throws ExecutionException {
                    return new ApiHttpRequestRunProfileState();
                }

                @NotNull
                @Override
                public String getName() {
                    return "执行Api请求";
                }

                @Nullable
                @Override
                public Icon getIcon() {
                    return AllIcons.Actions.Execute;
                }
            });
            ExecutionManager.getInstance(project).restartRunProfile(builder.build());
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    public static class WithEnv extends RunApiRequestAction {

        public WithEnv(ApiApiBlock apiBlock, String env) {
            super(apiBlock, env);
        }
    }
}
