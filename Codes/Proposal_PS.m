function [SAM_A,WW] = Proposal_PS(WWB,AB,depth_diff,d18O,C14_Table,Age_Info,data_full,param,target,mode,QQ,ACC_MODEL,ACC_CONTRACTION,ACC_STEADY,ACC_EXPANSION)

a = param.a_d18O;
b = param.b_d18O;
log_tail = gammaln(a+0.5) - gammaln(a) - 0.5*log(2*pi*b);

a_C14 = param.a_C14;
b_C14 = param.b_C14;


S = param.nParticles;
v = data_full.PTCL_BW;

R = data_full.R;

phi_I = data_full.phi_I;
phi_C = data_full.phi_C;
phi_M = data_full.phi_M;
phi_E = data_full.phi_E;
PHI = [phi_C;phi_M;phi_E;phi_I];
PHI = log(PHI);

% data_full.lower_sedrate = 0;
% data_full.upper_sedrate = inf;

if isempty(WWB) == 1
    % Sample ages:
    if size(QQ,2) == S
        index = ceil(S*rand(1,5*S));
        QQ = QQ(index);
        UU = rand(1,5*S)*(4*v) + (QQ-2*v);
        UU = UU((UU>=data_full.min)&(UU<=data_full.max));
        SAM_A = UU(1:S);
    else
        UU = rand(1,5*S)*(4*QQ(2)) + (QQ(1)-2*QQ(2));
        UU = UU((UU>=data_full.min)&(UU<=data_full.max));
        SAM_A = UU(1:S);
    end
    
    % Compute weights:
    MargLik = zeros(1,S);
    if ~strcmp(mode,'C14') && ~isnan(d18O(1))
        mu = interp1(target.stack(:,1),target.stack(:,2),SAM_A);
        sig = interp1(target.stack(:,1),target.stack(:,3),SAM_A);
        N = sum(~isnan(d18O));
        for n = 1:N
            % AA = (1-q)*exp(-(d18O(n)-mu).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu-d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu+d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2);
            % MargLik = MargLik + log(AA);
            MargLik = MargLik - (a+0.5)*log(1+(d18O(n)-mu).^2./(2*b*sig.^2)) - log(sig) + log_tail;
        end
    end
    if strcmp(mode,'d18O') == 0 && ~isempty(C14_Table)
        MargLik = MargLik + EP_Y(SAM_A,C14_Table,target.cal_curve,a_C14,b_C14);
    end
    
    if ~isnan(Age_Info(1))
        if Age_Info(3) == 0
            MargLik = MargLik - (SAM_A-Age_Info(1)).^2./(2*Age_Info(2).^2);
        elseif Age_Info(3) == 1
            index = (SAM_A>=Age_Info(1)-Age_Info(2))&(SAM_A<=Age_Info(1)+Age_Info(2));
            MargLik(~index) = -inf;
        end
    end
    
    MargLik(SAM_A<data_full.min|SAM_A>data_full.max) = -inf;
    MargLik(isnan(MargLik)) = -inf;
    
    if ~isnan(data_full.max)
        MargLik(SAM_A>data_full.max) = -inf;
    end
    if ~isnan(data_full.min)
        MargLik(SAM_A<data_full.min) = -inf;
    end
    
    WW = MargLik;
else
    if size(WWB,1) == 1
        index = (~isinf(WWB));
        AB_TABLE = AB(index);
        WB_TABLE = WWB(index);
        
        % AB_TABLE = AB(1:min(asamples,S));
        % WB_TABLE = WWB(1:min(asamples,S));
        
        % Sample ages:
        if size(QQ,2) == S
            index = ceil(S*rand(1,15*S));
            QQ = QQ(index);
            UU = rand(1,15*S)*(4*v) + (QQ-2*v);
            UU = UU((UU>=data_full.min)&(UU<=data_full.max));
            SAM_A = reshape(UU(1:3*S),[3,S]);
        else
            UU = rand(1,15*S)*(4*QQ(2)) + (QQ(1)-2*QQ(2));
            UU = UU((UU>=data_full.min)&(UU<=data_full.max));
            SAM_A = reshape(UU(1:3*S),[3,S]);
        end
        
        % Compute weights:
        WW = zeros(3,S);
        
        RR = interp1(R(:,1),R(:,2),AB_TABLE');
        RR = repmat(RR,[1,S]);
        
        % Z == 1:
        MargLik = PHI(4,1) + WB_TABLE';
        
        VV = (AB_TABLE'-SAM_A(1,:))./(RR.*depth_diff);
        
        MargLik = MargLik + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV,'linear',-56) - ACC_CONTRACTION;
        index = (VV<=0)|(VV>=0.9220);
        MargLik(index) = -inf;
        
        index = (VV<data_full.lower_sedrate)|(VV>data_full.upper_sedrate);
        MargLik(index) = -inf;
        
        AMAX = max(MargLik);
        MargLik = AMAX + log(sum(exp(MargLik-AMAX)));
        
        if ~strcmp(mode,'C14') && ~isnan(d18O(1))
            % MargLik = MargLik + log((1-q)*exp(EP_V(SAM_A(1,:),zeros(1,S),d18O,stack))+q*exp(EP_V(SAM_A(1,:),ones(1,S),d18O,stack)));
            mu = interp1(target.stack(:,1),target.stack(:,2),SAM_A(1,:));
            sig = interp1(target.stack(:,1),target.stack(:,3),SAM_A(1,:));
            N = sum(~isnan(d18O));
            for n = 1:N
                % AA = (1-q)*exp(-(d18O(n)-mu).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu-d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu+d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2);
                % MargLik = MargLik + log(AA);
                MargLik = MargLik - (a+0.5)*log(1+(d18O(n)-mu).^2./(2*b*sig.^2)) - log(sig) + log_tail;
            end
        end
        if strcmp(mode,'d18O') == 0 && ~isempty(C14_Table)
            MargLik = MargLik + EP_Y(SAM_A(1,:),C14_Table,target.cal_curve,a_C14,b_C14);
        end
        
        if ~isnan(Age_Info(1))
            if Age_Info(3) == 0
                MargLik = MargLik - (SAM_A(1,:)-Age_Info(1)).^2./(2*Age_Info(2).^2);
            elseif Age_Info(3) == 1
                index = (SAM_A(1,:)>=Age_Info(1)-Age_Info(2))&(SAM_A(1,:)<=Age_Info(1)+Age_Info(2));
                MargLik(~index) = -inf;
            end
        end
        %{
        if size(QQ,2) == S
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(1,:)-QQ(1,:)).^2./(2*b*v^2));
        else
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(1,:)-QQ(1)).^2./(2*b*QQ(2)));
        end
        %}
        MargLik(SAM_A(1,:)<data_full.min) = -inf;
        MargLik(isnan(MargLik)) = -inf;
        
        if ~isnan(data_full.max)
            MargLik(SAM_A(1,:)>data_full.max) = -inf;
        end
        if ~isnan(data_full.min)
            MargLik(SAM_A(1,:)<data_full.min) = -inf;
        end
        
        WW(1,:) = MargLik;
        
        % Z == 2:
        MargLik = PHI(4,2) + WB_TABLE';
        
        VV = (AB_TABLE'-SAM_A(2,:))./(RR.*depth_diff);
        
        MargLik = MargLik + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV,'linear',-56) - ACC_STEADY;
        index = (VV<0.9220)|(VV>=1.0850);
        MargLik(index) = -inf;
        
        index = (VV<data_full.lower_sedrate)|(VV>data_full.upper_sedrate);
        MargLik(index) = -inf;
        
        AMAX = max(MargLik);
        MargLik = AMAX + log(sum(exp(MargLik-AMAX)));
        
        if ~strcmp(mode,'C14') && ~isnan(d18O(1))
            % MargLik = MargLik + log((1-q)*exp(EP_V(SAM_A(2,:),zeros(1,S),d18O,stack))+q*exp(EP_V(SAM_A(2,:),ones(1,S),d18O,stack)));
            mu = interp1(target.stack(:,1),target.stack(:,2),SAM_A(2,:));
            sig = interp1(target.stack(:,1),target.stack(:,3),SAM_A(2,:));
            N = sum(~isnan(d18O));
            for n = 1:N
                % AA = (1-q)*exp(-(d18O(n)-mu).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu-d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu+d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2);
                % MargLik = MargLik + log(AA);
                MargLik = MargLik - (a+0.5)*log(1+(d18O(n)-mu).^2./(2*b*sig.^2)) - log(sig) + log_tail;
            end
        end
        if strcmp(mode,'d18O') == 0 && ~isempty(C14_Table)
            MargLik = MargLik + EP_Y(SAM_A(2,:),C14_Table,target.cal_curve,a_C14,b_C14);
        end
        
        if ~isnan(Age_Info(1))
            if Age_Info(3) == 0
                MargLik = MargLik - (SAM_A(2,:)-Age_Info(1)).^2./(2*Age_Info(2).^2);
            elseif Age_Info(3) == 1
                index = (SAM_A(2,:)>=Age_Info(1)-Age_Info(2))&(SAM_A(2,:)<=Age_Info(1)+Age_Info(2));
                MargLik(~index) = -inf;
            end
        end
        %{
        if size(QQ,2) == S
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(2,:)-QQ(2,:)).^2./(2*b*v^2));
        else
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(2,:)-QQ(1)).^2./(2*b*QQ(2)));
        end
        %}
        MargLik(SAM_A(2,:)<data_full.min) = -inf;
        MargLik(isnan(MargLik)) = -inf;
        
        if ~isnan(data_full.max)
            MargLik(SAM_A(2,:)>data_full.max) = -inf;
        end
        if ~isnan(data_full.min)
            MargLik(SAM_A(2,:)<data_full.min) = -inf;
        end
        
        WW(2,:) = MargLik;
        
        % Z == 3:
        MargLik = PHI(4,3) + WB_TABLE';
        
        VV = (AB_TABLE'-SAM_A(3,:))./(RR.*depth_diff);
        
        MargLik = MargLik + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV,'linear',-56) - ACC_EXPANSION;
        index = (VV<1.0850);
        MargLik(index) = -inf;
        
        index = (VV<data_full.lower_sedrate)|(VV>data_full.upper_sedrate);
        MargLik(index) = -inf;
        
        AMAX = max(MargLik);
        MargLik = AMAX + log(sum(exp(MargLik-AMAX)));
        
        if ~strcmp(mode,'C14') && ~isnan(d18O(1))
            % MargLik = MargLik + log((1-q)*exp(EP_V(SAM_A(3,:),zeros(1,S),d18O,stack))+q*exp(EP_V(SAM_A(3,:),ones(1,S),d18O,stack)));
            mu = interp1(target.stack(:,1),target.stack(:,2),SAM_A(3,:));
            sig = interp1(target.stack(:,1),target.stack(:,3),SAM_A(3,:));
            N = sum(~isnan(d18O));
            for n = 1:N
                % AA = (1-q)*exp(-(d18O(n)-mu).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu-d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu+d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2);
                % MargLik = MargLik + log(AA);
                MargLik = MargLik - (a+0.5)*log(1+(d18O(n)-mu).^2./(2*b*sig.^2)) - log(sig) + log_tail;
            end
        end
        if strcmp(mode,'d18O') == 0 && ~isempty(C14_Table)
            MargLik = MargLik + EP_Y(SAM_A(3,:),C14_Table,target.cal_curve,a_C14,b_C14);
        end
        
        if ~isnan(Age_Info(1))
            if Age_Info(3) == 0
                MargLik = MargLik - (SAM_A(3,:)-Age_Info(1)).^2./(2*Age_Info(2).^2);
            elseif Age_Info(3) == 1
                index = (SAM_A(3,:)>=Age_Info(1)-Age_Info(2))&(SAM_A(3,:)<=Age_Info(1)+Age_Info(2));
                MargLik(~index) = -inf;
            end
        end
        %{
        if size(QQ,2) == S
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(3,:)-QQ(1,:)).^2./(2*b*v^2));
        else
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(3,:)-QQ(1)).^2./(2*b*QQ(2)));
        end
        %}
        MargLik(SAM_A(3,:)<data_full.min) = -inf;
        MargLik(isnan(MargLik)) = -inf;
        
        if ~isnan(data_full.max)
            MargLik(SAM_A(3,:)>data_full.max) = -inf;
        end
        if ~isnan(data_full.min)
            MargLik(SAM_A(3,:)<data_full.min) = -inf;
        end
        
        WW(3,:) = MargLik;
    else
        index = (~isinf(WWB(1,:)));
        AB_TABLE_C = AB(1,index);
        WB_TABLE_C = WWB(1,index);
        
        index = (~isinf(WWB(2,:)));
        AB_TABLE_M = AB(2,index);
        WB_TABLE_M = WWB(2,index);
        
        index = (~isinf(WWB(3,:)));
        AB_TABLE_E = AB(3,index);
        WB_TABLE_E = WWB(3,index);
        
        % Sample ages:
        if size(QQ,2) == S
            index = ceil(S*rand(1,15*S));
            QQ = QQ(index);
            UU = rand(1,15*S)*(4*v) + (QQ-2*v);
            UU = UU((UU>=data_full.min)&(UU<=data_full.max));
            SAM_A = reshape(UU(1:3*S),[3,S]);
        else
            UU = rand(1,15*S)*(4*QQ(2)) + (QQ(1)-2*QQ(2));
            UU = UU((UU>=data_full.min)&(UU<=data_full.max));
            SAM_A = reshape(UU(1:3*S),[3,S]);
        end
        
        % Compute weights:
        WW = zeros(3,S);
        
        RR_C = interp1(R(:,1),R(:,2),AB_TABLE_C');
        RR_C = repmat(RR_C,[1,S]);
        
        RR_M = interp1(R(:,1),R(:,2),AB_TABLE_M');
        RR_M = repmat(RR_M,[1,S]);
        
        RR_E = interp1(R(:,1),R(:,2),AB_TABLE_E');
        RR_E = repmat(RR_E,[1,S]);
        
        % Z == 1:
        MargLik_C = PHI(1,1) + WB_TABLE_C';
        MargLik_M = PHI(2,1) + WB_TABLE_M';
        MargLik_E = PHI(3,1) + WB_TABLE_E';
        
        VV_C = (AB_TABLE_C'-SAM_A(1,:))./(RR_C.*depth_diff);
        VV_M = (AB_TABLE_M'-SAM_A(1,:))./(RR_M.*depth_diff);
        VV_E = (AB_TABLE_E'-SAM_A(1,:))./(RR_E.*depth_diff);
        
        MargLik_C = MargLik_C + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_C,'linear',-56) - ACC_CONTRACTION;
        index = (VV_C<=0)|(VV_C>=0.9220);
        MargLik_C(index) = -inf;
        
        MargLik_M = MargLik_M + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_M,'linear',-56) - ACC_CONTRACTION;
        index = (VV_M<=0)|(VV_M>=0.9220);
        MargLik_M(index) = -inf;
        
        MargLik_E = MargLik_E + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_E,'linear',-56) - ACC_CONTRACTION;
        index = (VV_E<=0)|(VV_E>=0.9220);
        MargLik_E(index) = -inf;
        
        index = (VV_C<data_full.lower_sedrate)|(VV_C>data_full.upper_sedrate);
        MargLik_C(index) = -inf;
        
        index = (VV_M<data_full.lower_sedrate)|(VV_M>data_full.upper_sedrate);
        MargLik_M(index) = -inf;
        
        index = (VV_E<data_full.lower_sedrate)|(VV_E>data_full.upper_sedrate);
        MargLik_E(index) = -inf;
        
        MargLik = [MargLik_C;MargLik_M;MargLik_E];
        
        AMAX = max(MargLik);
        MargLik = AMAX + log(sum(exp(MargLik-AMAX)));
        
        if ~strcmp(mode,'C14') && ~isnan(d18O(1))
            % MargLik = MargLik + log((1-q)*exp(EP_V(SAM_A(1,:),zeros(1,S),d18O,stack))+q*exp(EP_V(SAM_A(1,:),ones(1,S),d18O,stack)));
            mu = interp1(target.stack(:,1),target.stack(:,2),SAM_A(1,:));
            sig = interp1(target.stack(:,1),target.stack(:,3),SAM_A(1,:));
            N = sum(~isnan(d18O));
            for n = 1:N
                % AA = (1-q)*exp(-(d18O(n)-mu).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu-d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu+d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2);
                % MargLik = MargLik + log(AA);
                MargLik = MargLik - (a+0.5)*log(1+(d18O(n)-mu).^2./(2*b*sig.^2)) - log(sig) + log_tail;
            end
        end
        if strcmp(mode,'d18O') == 0 && ~isempty(C14_Table)
            MargLik = MargLik + EP_Y(SAM_A(1,:),C14_Table,target.cal_curve,a_C14,b_C14);
        end
        
        if ~isnan(Age_Info(1))
            if Age_Info(3) == 0
                MargLik = MargLik - (SAM_A(1,:)-Age_Info(1)).^2./(2*Age_Info(2).^2);
            elseif Age_Info(3) == 1
                index = (SAM_A(1,:)>=Age_Info(1)-Age_Info(2))&(SAM_A(1,:)<=Age_Info(1)+Age_Info(2));
                MargLik(~index) = -inf;
            end
        end
        %{
        if size(QQ,2) == S
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(1,:)-QQ(1,:)).^2./(2*b*v^2));
        else
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(1,:)-QQ(1)).^2./(2*b*QQ(2)));
        end
        %}
        MargLik(SAM_A(1,:)<data_full.min) = -inf;
        MargLik(isnan(MargLik)) = -inf;
        
        if ~isnan(data_full.max)
            MargLik(SAM_A(1,:)>data_full.max) = -inf;
        end
        if ~isnan(data_full.min)
            MargLik(SAM_A(1,:)<data_full.min) = -inf;
        end
        
        WW(1,:) = MargLik;
        
        % Z == 2:
        MargLik_C = PHI(1,2) + WB_TABLE_C';
        MargLik_M = PHI(2,2) + WB_TABLE_M';
        MargLik_E = PHI(3,2) + WB_TABLE_E';
        
        VV_C = (AB_TABLE_C'-SAM_A(2,:))./(RR_C.*depth_diff);
        VV_M = (AB_TABLE_M'-SAM_A(2,:))./(RR_M.*depth_diff);
        VV_E = (AB_TABLE_E'-SAM_A(2,:))./(RR_E.*depth_diff);
        
        MargLik_C = MargLik_C + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_C,'linear',-56) - ACC_STEADY;
        index = (VV_C<0.9220)|(VV_C>=1.0850);
        MargLik_C(index) = -inf;
        
        MargLik_M = MargLik_M + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_M,'linear',-56) - ACC_STEADY;
        index = (VV_M<0.9220)|(VV_M>=1.0850);
        MargLik_M(index) = -inf;
        
        MargLik_E = MargLik_E + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_E,'linear',-56) - ACC_STEADY;
        index = (VV_E<0.9220)|(VV_E>=1.0850);
        MargLik_E(index) = -inf;
        
        index = (VV_C<data_full.lower_sedrate)|(VV_C>data_full.upper_sedrate);
        MargLik_C(index) = -inf;
        
        index = (VV_M<data_full.lower_sedrate)|(VV_M>data_full.upper_sedrate);
        MargLik_M(index) = -inf;
        
        index = (VV_E<data_full.lower_sedrate)|(VV_E>data_full.upper_sedrate);
        MargLik_E(index) = -inf;
        
        MargLik = [MargLik_C;MargLik_M;MargLik_E];
        
        AMAX = max(MargLik);
        MargLik = AMAX + log(sum(exp(MargLik-AMAX)));
        
        if ~strcmp(mode,'C14') && ~isnan(d18O(1))
            % MargLik = MargLik + log((1-q)*exp(EP_V(SAM_A(2,:),zeros(1,S),d18O,stack))+q*exp(EP_V(SAM_A(2,:),ones(1,S),d18O,stack)));
            mu = interp1(target.stack(:,1),target.stack(:,2),SAM_A(2,:));
            sig = interp1(target.stack(:,1),target.stack(:,3),SAM_A(2,:));
            N = sum(~isnan(d18O));
            for n = 1:N
                % AA = (1-q)*exp(-(d18O(n)-mu).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu-d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu+d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2);
                % MargLik = MargLik + log(AA);
                MargLik = MargLik - (a+0.5)*log(1+(d18O(n)-mu).^2./(2*b*sig.^2)) - log(sig) + log_tail;
            end
        end
        if strcmp(mode,'d18O') == 0 && ~isempty(C14_Table)
            MargLik = MargLik + EP_Y(SAM_A(2,:),C14_Table,target.cal_curve,a_C14,b_C14);
        end
        
        if ~isnan(Age_Info(1))
            if Age_Info(3) == 0
                MargLik = MargLik - (SAM_A(2,:)-Age_Info(1)).^2./(2*Age_Info(2).^2);
            elseif Age_Info(3) == 1
                index = (SAM_A(2,:)>=Age_Info(1)-Age_Info(2))&(SAM_A(2,:)<=Age_Info(1)+Age_Info(2));
                MargLik(~index) = -inf;
            end
        end
        %{
        if size(QQ,2) == S
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(2,:)-QQ(2,:)).^2./(2*b*v^2));
        else
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(2,:)-QQ(1)).^2./(2*b*QQ(2)));
        end
        %}
        MargLik(SAM_A(2,:)<data_full.min) = -inf;
        MargLik(isnan(MargLik)) = -inf;
        
        if ~isnan(data_full.max)
            MargLik(SAM_A(2,:)>data_full.max) = -inf;
        end
        if ~isnan(data_full.min)
            MargLik(SAM_A(2,:)<data_full.min) = -inf;
        end
        
        WW(2,:) = MargLik;
        
        % Z == 3:
        MargLik_C = PHI(1,3) + WB_TABLE_C';
        MargLik_M = PHI(2,3) + WB_TABLE_M';
        MargLik_E = PHI(3,3) + WB_TABLE_E';
        
        VV_C = (AB_TABLE_C'-SAM_A(3,:))./(RR_C.*depth_diff);
        VV_M = (AB_TABLE_M'-SAM_A(3,:))./(RR_M.*depth_diff);
        VV_E = (AB_TABLE_E'-SAM_A(3,:))./(RR_E.*depth_diff);
        
        MargLik_C = MargLik_C + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_C,'linear',-56) - ACC_EXPANSION;
        index = (VV_C<1.0850);
        MargLik_C(index) = -inf;
        
        MargLik_M = MargLik_M + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_M,'linear',-56) - ACC_EXPANSION;
        index = (VV_M<1.0850);
        MargLik_M(index) = -inf;
        
        MargLik_E = MargLik_E + interp1(ACC_MODEL(:,1),ACC_MODEL(:,2),VV_E,'linear',-56) - ACC_EXPANSION;
        index = (VV_E<1.0850);
        MargLik_E(index) = -inf;
        
        index = (VV_C<data_full.lower_sedrate)|(VV_C>data_full.upper_sedrate);
        MargLik_C(index) = -inf;
        
        index = (VV_M<data_full.lower_sedrate)|(VV_M>data_full.upper_sedrate);
        MargLik_M(index) = -inf;
        
        index = (VV_E<data_full.lower_sedrate)|(VV_E>data_full.upper_sedrate);
        MargLik_E(index) = -inf;
        
        MargLik = [MargLik_C;MargLik_M;MargLik_E];
        
        AMAX = max(MargLik);
        MargLik = AMAX + log(sum(exp(MargLik-AMAX)));
        
        if ~strcmp(mode,'C14') && ~isnan(d18O(1))
            % MargLik = MargLik + log((1-q)*exp(EP_V(SAM_A(3,:),zeros(1,S),d18O,stack))+q*exp(EP_V(SAM_A(3,:),ones(1,S),d18O,stack)));
            mu = interp1(target.stack(:,1),target.stack(:,2),SAM_A(3,:));
            sig = interp1(target.stack(:,1),target.stack(:,3),SAM_A(3,:));
            N = sum(~isnan(d18O));
            for n = 1:N
                % AA = (1-q)*exp(-(d18O(n)-mu).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu-d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2) + q/2*exp(-(d18O(n)-mu+d*sig).^2./(2*sig.^2))./sqrt(2*pi*sig.^2);
                % MargLik = MargLik + log(AA);
                MargLik = MargLik - (a+0.5)*log(1+(d18O(n)-mu).^2./(2*b*sig.^2)) - log(sig) + log_tail;
            end
        end
        if strcmp(mode,'d18O') == 0 && ~isempty(C14_Table)
            MargLik = MargLik + EP_Y(SAM_A(3,:),C14_Table,target.cal_curve,a_C14,b_C14);
        end
        
        if ~isnan(Age_Info(1))
            if Age_Info(3) == 0
                MargLik = MargLik - (SAM_A(3,:)-Age_Info(1)).^2./(2*Age_Info(2).^2);
            elseif Age_Info(3) == 1
                index = (SAM_A(3,:)>Age_Info(1)-Age_Info(2))&(SAM_A(3,:)<Age_Info(1)+Age_Info(2));
                MargLik(~index) = -inf;
            end
        end
        %{
        if size(QQ,2) == S
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(3,:)-QQ(3,:)).^2./(2*b*v^2));
        else
            MargLik = MargLik + (a+0.5)*log(1+(SAM_A(3,:)-QQ(1)).^2./(2*b*QQ(2)));
        end
        %}
        MargLik(SAM_A(3,:)<data_full.min) = -inf;
        MargLik(isnan(MargLik)) = -inf;
        
        if ~isnan(data_full.max)
            MargLik(SAM_A(3,:)>data_full.max) = -inf;
        end
        if ~isnan(data_full.min)
            MargLik(SAM_A(3,:)<data_full.min) = -inf;
        end
        
        WW(3,:) = MargLik;
    end
end


end

